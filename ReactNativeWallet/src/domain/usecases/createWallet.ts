import type { Network } from '@domain/entities/Network';
import type { Wallet } from '@domain/entities/Wallet';
import { generateMnemonic, validateMnemonic } from '@domain/services/MnemonicService';
import { deriveWalletFromMnemonic } from '@domain/services/WalletDerivationService';
import { WalletRepository } from '@domain/repositories/WalletRepository';

export type CreateWalletResult = {
  wallet: Wallet;
  mnemonic: string;
};

export async function createNewWallet(params: {
  repository: WalletRepository;
  network: Network;
  name?: string;
}): Promise<CreateWalletResult> {
  const { repository, network, name } = params;
  const mnemonic = generateMnemonic();
  const { wallet } = deriveWalletFromMnemonic({
    mnemonic,
    network,
    isImported: false,
    name,
  });

  await repository.saveWallet(wallet, mnemonic);
  await repository.setActiveWallet(wallet.id);

  return { wallet, mnemonic };
}

export async function importWallet(params: {
  repository: WalletRepository;
  mnemonic: string;
  network: Network;
  name?: string;
}): Promise<CreateWalletResult> {
  const { repository, mnemonic, network, name } = params;

  if (!validateMnemonic(mnemonic)) {
    throw new Error('Invalid mnemonic phrase');
  }

  const { wallet } = deriveWalletFromMnemonic({
    mnemonic,
    network,
    isImported: true,
    name,
  });

  const existingWallets = await repository.listWallets();
  const duplicate = existingWallets.find(
    existing =>
      existing.fingerprint === wallet.fingerprint &&
      existing.network.chainId === wallet.network.chainId,
  );
  if (duplicate) {
    throw new Error('WALLET_ALREADY_IMPORTED');
  }

  await repository.saveWallet(wallet, mnemonic.trim());
  await repository.setActiveWallet(wallet.id);

  return { wallet, mnemonic: mnemonic.trim() };
}
