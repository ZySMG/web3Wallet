import { create } from 'zustand';
import type { Wallet } from '@domain/entities/Wallet';
import type { Balance } from '@domain/entities/Balance';
import type { Transaction } from '@domain/entities/Transaction';
import type { GasEstimate } from '@domain/entities/GasEstimate';
import { SUPPORTED_CURRENCIES } from '@domain/entities/Currency';
import { WalletRepository } from '@domain/repositories/WalletRepository';
import { PriceService } from '@data/services/PriceService';
import { EtherscanService } from '@data/services/EtherscanService';
import {
  createNewWallet,
  importWallet,
  type CreateWalletResult,
} from '@domain/usecases/createWallet';
import { resolveBalances } from '@domain/usecases/resolveBalances';
import { fetchTransactionHistory } from '@domain/usecases/fetchTransactionHistory';
import { estimateGas } from '@domain/usecases/estimateGas';
import { sendTransaction } from '@domain/usecases/sendTransaction';

const walletRepository = new WalletRepository();
const priceService = new PriceService();
const etherscanService = new EtherscanService(priceService);

const BALANCE_REFRESH_INTERVAL = 20_000;
const TRANSACTION_REFRESH_INTERVAL = 20_000;
const REFRESH_TIMEOUT_MS = 12_000;

type WalletState = {
  wallets: Wallet[];
  activeWallet: Wallet | null;
  balances: Balance[];
  transactions: Transaction[];
  portfolioValue: string;
  change24h: string;
  loadingBalances: boolean;
  loadingTransactions: boolean;
  isInitializing: boolean;
  lastBalancesFetch: number;
  lastTransactionsFetch: number;
  error?: string;
  initialize: () => Promise<void>;
  createWallet: (params: {
    network: Wallet['network'];
    name?: string;
  }) => Promise<CreateWalletResult>;
  importWallet: (params: {
    mnemonic: string;
    network: Wallet['network'];
    name?: string;
  }) => Promise<CreateWalletResult>;
  selectWallet: (walletId: string) => Promise<void>;
  deleteWallet: (walletId: string) => Promise<void>;
  clearWallets: () => Promise<void>;
  refreshBalances: (options?: { force?: boolean }) => Promise<void>;
  refreshTransactions: (options?: { force?: boolean }) => Promise<void>;
  estimateGas: (params: { to: string; amount: string; currency: Balance['currency'] }) => Promise<GasEstimate>;
  sendTransaction: (params: {
    to: string;
    amount: string;
    currency: Balance['currency'];
    gasEstimate?: GasEstimate;
  }) => Promise<string>;
};

export const useWalletStore = create<WalletState>((set, get) => ({
  wallets: [],
  activeWallet: null,
  balances: [],
  transactions: [],
  portfolioValue: '$0.00',
  change24h: '+0.00%',
  loadingBalances: false,
  loadingTransactions: false,
  isInitializing: false,
  lastBalancesFetch: 0,
  lastTransactionsFetch: 0,
  async initialize() {
    set({ isInitializing: true, error: undefined });
    try {
      const wallets = await walletRepository.listWallets();
      const activeWallet = await walletRepository.getActiveWallet();
      set({ wallets, activeWallet: activeWallet ?? null });
      if (activeWallet) {
        await Promise.all([
          get().refreshBalances({ force: true }),
          get().refreshTransactions({ force: true }),
        ]);
      }
    } catch (error) {
      set({ error: (error as Error).message });
    } finally {
      set({ isInitializing: false });
    }
  },
  async createWallet({ network, name }) {
    const result = await createNewWallet({
      repository: walletRepository,
      network,
      name,
    });
    const { wallet } = result;
    const wallets = await walletRepository.listWallets();
    set({
      wallets,
      activeWallet: wallet,
      lastBalancesFetch: 0,
      lastTransactionsFetch: 0,
    });
    await get().refreshBalances({ force: true });
    await get().refreshTransactions({ force: true });
    return result;
  },
  async importWallet({ mnemonic, network, name }) {
    const result = await importWallet({
      repository: walletRepository,
      mnemonic,
      network,
      name,
    });
    const { wallet } = result;
    const wallets = await walletRepository.listWallets();
    set({
      wallets,
      activeWallet: wallet,
      lastBalancesFetch: 0,
      lastTransactionsFetch: 0,
    });
    await get().refreshBalances({ force: true });
    await get().refreshTransactions({ force: true });
    return result;
  },
  async selectWallet(walletId) {
    await walletRepository.setActiveWallet(walletId);
    const wallets = await walletRepository.listWallets();
    const activeWallet = wallets.find(wallet => wallet.id === walletId) ?? null;
    set({
      wallets,
      activeWallet,
      lastBalancesFetch: 0,
      lastTransactionsFetch: 0,
    });
    await get().refreshBalances({ force: true });
    await get().refreshTransactions({ force: true });
  },
  async deleteWallet(walletId) {
    const currentWallets = await walletRepository.listWallets();
    if (currentWallets.length <= 1) {
      throw new Error('LAST_WALLET_DELETE_NOT_ALLOWED');
    }
    await walletRepository.removeWallet(walletId);
    const wallets = await walletRepository.listWallets();
    const activeWallet = await walletRepository.getActiveWallet();
    set({
      wallets,
      activeWallet: activeWallet ?? null,
      lastBalancesFetch: 0,
      lastTransactionsFetch: 0,
    });
    await get().refreshBalances({ force: true });
    await get().refreshTransactions({ force: true });
  },
  async clearWallets() {
    await walletRepository.clearAll();
    set({
      wallets: [],
      activeWallet: null,
      balances: [],
      transactions: [],
      portfolioValue: '$0.00',
      change24h: '+0.00%',
      lastBalancesFetch: 0,
      lastTransactionsFetch: 0,
    });
  },
  async refreshBalances(options) {
    const { force = false } = options ?? {};
    const wallet = get().activeWallet;
    if (!wallet) {
      return;
    }
    const now = Date.now();
    const lastFetch = get().lastBalancesFetch;
    if (!force && lastFetch && now - lastFetch < BALANCE_REFRESH_INTERVAL) {
      return;
    }
    set({ loadingBalances: true });
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), REFRESH_TIMEOUT_MS);
      const balances = await resolveBalances({
        etherscanService,
        wallet,
        currencies: SUPPORTED_CURRENCIES,
        signal: controller.signal,
      });
      clearTimeout(timeout);
      const totalUsd = balances.reduce(
        (sum, balance) => sum + (balance.usdValue ?? 0),
        0,
      );
      set({
        balances,
        portfolioValue: `$${totalUsd.toFixed(2)}`,
        change24h: totalUsd > 0 ? '+0.00%' : '--',
        lastBalancesFetch: now,
      });
    } catch (error) {
      set({ error: (error as Error).message });
    } finally {
      set({ loadingBalances: false });
    }
  },
  async refreshTransactions(options) {
    const { force = false } = options ?? {};
    const wallet = get().activeWallet;
    if (!wallet) {
      return;
    }
    const now = Date.now();
    const lastFetch = get().lastTransactionsFetch;
    if (!force && lastFetch && now - lastFetch < TRANSACTION_REFRESH_INTERVAL) {
      return;
    }
    set({ loadingTransactions: true });
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), REFRESH_TIMEOUT_MS);
      const transactions = await fetchTransactionHistory({
        etherscanService,
        wallet,
        limit: 50,
        signal: controller.signal,
      });
      clearTimeout(timeout);
      set({ transactions, lastTransactionsFetch: now });
    } catch (error) {
      set({ error: (error as Error).message });
    } finally {
      set({ loadingTransactions: false });
    }
  },
  async estimateGas({ to, amount, currency }) {
    const wallet = get().activeWallet;
    if (!wallet) {
      throw new Error('No active wallet');
    }
    return estimateGas({ wallet, to, amount, currency });
  },
  async sendTransaction({ to, amount, currency, gasEstimate }) {
    const wallet = get().activeWallet;
    if (!wallet) {
      throw new Error('No active wallet');
    }
    const txHash = await sendTransaction({
      repository: walletRepository,
      wallet,
      to,
      amount,
      currency,
      gasEstimate,
    });
    await Promise.all([
      get().refreshBalances({ force: true }),
      get().refreshTransactions({ force: true }),
    ]);
    return txHash;
  },
}));
