import type { Wallet } from '@domain/entities/Wallet';
import type { Currency } from '@domain/entities/Currency';
import { CURRENCIES } from '@domain/entities/Currency';
import type { Balance } from '@domain/entities/Balance';
import { EtherscanService } from '@data/services/EtherscanService';

export async function resolveBalances(params: {
  etherscanService: EtherscanService;
  wallet: Wallet;
  currencies: Currency[];
}): Promise<Balance[]> {
  const { etherscanService, wallet, currencies } = params;
  const set = new Set<string>();
  const combined = [...currencies];

  // Ensure ETH, USDC, USDT exist even if not provided.
  const fallbackCurrencies: Currency[] = [
    CURRENCIES.eth,
    CURRENCIES.usdc,
    CURRENCIES.usdt,
  ];

  fallbackCurrencies.forEach(currency => {
    if (!combined.find(item => item.symbol === currency.symbol)) {
      combined.push(currency);
    }
  });

  const uniqueCurrencies = combined.filter(currency => {
    const key = currency.contractAddress ?? currency.symbol;
    if (set.has(key)) {
      return false;
    }
    set.add(key);
    return true;
  });

  return etherscanService.getBalances(
    wallet.address,
    wallet.network,
    uniqueCurrencies,
  );
}
