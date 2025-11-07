import type { Network } from '@domain/entities/Network';
import type { Currency } from '@domain/entities/Currency';
import type { Balance } from '@domain/entities/Balance';
import {
  type Transaction,
  type TransactionDirection,
  type TransactionStatus,
} from '@domain/entities/Transaction';
import { createBalance } from '@domain/entities/Balance';
import { toDecimalAmount } from '@common/utils/eth';
import { formatCurrency } from '@common/utils/format';
import { EtherscanClient } from '../clients/etherscanClient';
import { PriceService } from './PriceService';
import { ENV } from '@app/config/env';
import { ETHERSCAN_V2_BASE_URL } from '@common/constants/ethereum';

type CacheEntry<T> = {
  timestamp: number;
  ttl: number;
  data: T;
};

const balanceCache = new Map<string, CacheEntry<Balance>>();
const transactionsCache = new Map<string, CacheEntry<Transaction[]>>();

function getCacheKey(address: string, chainId: number, suffix: string): string {
  return `${address.toLowerCase()}_${chainId}_${suffix}`;
}

export class EtherscanService {
  constructor(
    private readonly priceService: PriceService,
    private readonly apiKey: string = ENV.ETHERSCAN_API_KEY,
  ) {}

  private getClient(network: Network): EtherscanClient {
    return new EtherscanClient(this.apiKey, {
      baseURL: ETHERSCAN_V2_BASE_URL,
      chainId: String(network.chainId),
      enableLogging: true,
    });
  }

  async getBalance(
    walletAddress: string,
    network: Network,
    currency: Currency,
    options: { ttlMs?: number } = {},
  ): Promise<Balance> {
    const ttlMs = options.ttlMs ?? 20_000;
    const cacheKey = getCacheKey(
      walletAddress,
      network.chainId,
      currency.symbol,
    );
    const cached = balanceCache.get(cacheKey);
    const now = Date.now();

    if (cached && now - cached.timestamp < ttlMs) {
      return cached.data;
    }

    const client = this.getClient(network);
    const rawAmount = currency.contractAddress
      ? await client.getTokenBalance(walletAddress, currency.contractAddress)
      : await client.getEthBalance(walletAddress);

    const amount = toDecimalAmount(rawAmount, currency.decimals);
    const usdValue = await this.priceService.getUsdValue(currency.symbol, amount);

    const balance = createBalance({
      currency,
      amount,
      rawAmount,
      usdValue,
    });

    balanceCache.set(cacheKey, {
      data: balance,
      ttl: ttlMs,
      timestamp: now,
    });

    return balance;
  }

  async getBalances(
    walletAddress: string,
    network: Network,
    currencies: Currency[],
  ): Promise<Balance[]> {
    const balances = await Promise.all(
      currencies.map(async currency =>
        this.getBalance(walletAddress, network, currency),
      ),
    );
    return balances.sort(
      (a, b) => Number(b.usdValue ?? 0) - Number(a.usdValue ?? 0),
    );
  }

  async getTransactions(
    walletAddress: string,
    network: Network,
    limit = 50,
    options: { ttlMs?: number } = {},
  ): Promise<Transaction[]> {
    const ttlMs = options.ttlMs ?? 90_000;
    const cacheKey = getCacheKey(walletAddress, network.chainId, 'transactions');
    const now = Date.now();

    const cached = transactionsCache.get(cacheKey);
    if (cached && now - cached.timestamp < ttlMs) {
      return cached.data;
    }

    const client = this.getClient(network);
    const [nativeTxs, tokenTxs] = await Promise.all([
      client.getTransactions(walletAddress, limit),
      client.getTokenTransfers(walletAddress, limit),
    ]);

    const transactions: Transaction[] = [
      ...nativeTxs.map(tx => this.mapNativeTransaction(tx, walletAddress, network)),
      ...tokenTxs.map(tx => this.mapTokenTransaction(tx, walletAddress, network)),
    ].filter(Boolean) as Transaction[];

    transactions.sort(
      (a, b) =>
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
    );

    const limited = transactions.slice(0, limit);

    transactionsCache.set(cacheKey, {
      data: limited,
      ttl: ttlMs,
      timestamp: now,
    });

    return limited;
  }

  private mapNativeTransaction(
    tx: any,
    ownerAddress: string,
    network: Network,
  ): Transaction | null {
    const rawValue = tx.value as string;
    const amount = toDecimalAmount(rawValue, network.nativeCurrency.decimals, 6);

    if (Number(amount) === 0) {
      const functionName = (tx.functionName as string | undefined)?.toLowerCase();
      if (functionName?.includes('transfer')) {
        return null;
      }
      const input = tx.input as string | undefined;
      if (input?.startsWith('0xa9059cbb')) {
        return null;
      }
    }

    return {
      hash: tx.hash,
      from: tx.from,
      to: tx.to,
      amount,
      currency: network.nativeCurrency,
      gasUsed: tx.gasUsed,
      gasPrice: tx.gasPrice,
      status: this.resolveStatus(tx),
      direction: this.resolveDirection(tx.from, ownerAddress),
      timestamp: new Date(Number(tx.timeStamp) * 1000).toISOString(),
      blockNumber: tx.blockNumber,
      network,
    };
  }

  private mapTokenTransaction(
    tx: any,
    ownerAddress: string,
    network: Network,
  ): Transaction {
    const decimals = Number(tx.tokenDecimal ?? tx.tokenDecimals ?? 18);
    const rawValue = tx.value as string;

    const currency: Currency = {
      symbol: (tx.tokenSymbol as string | undefined)?.toUpperCase() ?? 'TOKEN',
      name: tx.tokenName ?? 'Token',
      decimals,
      contractAddress: tx.contractAddress,
    };

    return {
      hash: tx.hash,
      from: tx.from,
      to: tx.to,
      amount: toDecimalAmount(rawValue, decimals, 6),
      currency,
      gasUsed: tx.gasUsed,
      gasPrice: tx.gasPrice,
      status: this.resolveStatus(tx),
      direction: this.resolveDirection(tx.from, ownerAddress),
      timestamp: new Date(Number(tx.timeStamp) * 1000).toISOString(),
      blockNumber: tx.blockNumber,
      network,
    };
  }

  private resolveStatus(tx: any): TransactionStatus {
    const receiptStatus = tx.txreceipt_status ?? tx.receiptStatus;
    if (receiptStatus !== undefined && receiptStatus !== null) {
      const normalized = String(receiptStatus);
      if (normalized === '1') {
        return 'success';
      }
      if (normalized === '0') {
        return 'failed';
      }
    }

    const isError = tx.isError;
    if (isError !== undefined && isError !== null) {
      const normalized = String(isError);
      if (normalized === '0') {
        return 'success';
      }
      if (normalized === '1') {
        return 'failed';
      }
    }

    if (typeof tx.status === 'string') {
      const normalized = tx.status.toLowerCase();
      if (normalized === 'success' || normalized === 'ok') {
        return 'success';
      }
      if (normalized === 'fail' || normalized === 'failed' || normalized === 'error') {
        return 'failed';
      }
      if (normalized === 'pending') {
        return 'pending';
      }
    }

    const confirmations = Number(tx.confirmations);
    if (!Number.isNaN(confirmations)) {
      return confirmations > 0 ? 'success' : 'pending';
    }

    return 'pending';
  }

  private resolveDirection(
    fromAddress: string,
    ownerAddress: string,
  ): TransactionDirection {
    return fromAddress.toLowerCase() === ownerAddress.toLowerCase()
      ? 'outbound'
      : 'inbound';
  }

  async getPortfolioSummary(
    walletAddress: string,
    network: Network,
    currencies: Currency[],
  ): Promise<{
    totalUsdValue: string;
    topBalances: Balance[];
    change24h: string;
  }> {
    const balances = await this.getBalances(walletAddress, network, currencies);
    const usdValues = balances.map(balance => balance.usdValue ?? 0);
    const totalUsd = usdValues.reduce((sum, value) => sum + value, 0);
    const averageUsd =
      usdValues.length > 0
        ? usdValues.reduce((sum, value) => sum + value, 0) / usdValues.length
        : 0;
    const change = averageUsd * 0.02; // Placeholder for now

    const changePct = totalUsd === 0 ? 0 : (change / totalUsd) * 100;

    return {
      totalUsdValue: formatCurrency(totalUsd),
      topBalances: balances.slice(0, 3),
      change24h: `${changePct >= 0 ? '+' : '-'}${Math.abs(changePct).toFixed(2)}%`,
    };
  }
}
