import type { Wallet } from '@domain/entities/Wallet';
import { removeItem, getItem, setItem } from '@data/storage/AsyncStorageAdapter';
import { getMnemonic, removeMnemonic, storeMnemonic } from '@data/storage/SecureStorage';

const WALLETS_KEY = '@web3wallet/wallets';
const ACTIVE_WALLET_KEY = '@web3wallet/active_wallet_id';

export class WalletRepository {
  async listWallets(): Promise<Wallet[]> {
    const wallets = await getItem<Wallet[]>(WALLETS_KEY);
    return wallets ?? [];
  }

  async saveWallet(wallet: Wallet, mnemonic: string): Promise<void> {
    const wallets = await this.listWallets();
    const existingIndex = wallets.findIndex(item => item.id === wallet.id);
    const updated = [...wallets];

    if (existingIndex >= 0) {
      updated[existingIndex] = wallet;
    } else {
      updated.push(wallet);
    }

    await setItem(WALLETS_KEY, updated);
    await storeMnemonic(wallet.fingerprint, mnemonic);
  }

  async getActiveWallet(): Promise<Wallet | null> {
    const wallets = await this.listWallets();
    const activeId = await getItem<string>(ACTIVE_WALLET_KEY);
    if (!activeId) {
      return wallets[0] ?? null;
    }
    return wallets.find(wallet => wallet.id === activeId) ?? null;
  }

  async setActiveWallet(walletId: string): Promise<void> {
    await setItem(ACTIVE_WALLET_KEY, walletId);
  }

  async removeWallet(walletId: string): Promise<void> {
    const wallets = await this.listWallets();
    const remaining = wallets.filter(wallet => wallet.id !== walletId);
    await setItem(WALLETS_KEY, remaining);

    const wallet = wallets.find(w => w.id === walletId);
    if (wallet) {
      await removeMnemonic(wallet.fingerprint);
    }

    const active = await getItem<string>(ACTIVE_WALLET_KEY);
    if (active === walletId) {
      if (remaining.length > 0) {
        await setItem(ACTIVE_WALLET_KEY, remaining[0].id);
      } else {
        await removeItem(ACTIVE_WALLET_KEY);
      }
    }
  }

  async getMnemonic(wallet: Wallet): Promise<string | null> {
    return getMnemonic(wallet.fingerprint);
  }

  async clearAll(): Promise<void> {
    const wallets = await this.listWallets();
    await removeItem(WALLETS_KEY);
    await removeItem(ACTIVE_WALLET_KEY);
    for (const wallet of wallets) {
      await removeMnemonic(wallet.fingerprint);
    }
  }
}
