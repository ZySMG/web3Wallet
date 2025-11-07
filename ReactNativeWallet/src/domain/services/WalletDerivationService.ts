import { HDNodeWallet } from 'ethers';
import { DEFAULT_DERIVATION_PATH } from '@common/constants/ethereum';
import type { Network } from '@domain/entities/Network';
import { createWallet } from '@domain/entities/Wallet';

export type DerivedWallet = {
  wallet: ReturnType<typeof createWallet>;
  hdWallet: HDNodeWallet;
  privateKey: string;
  mnemonic: string;
};

export function deriveWalletFromMnemonic(params: {
  mnemonic: string;
  network: Network;
  derivationPath?: string;
  isImported?: boolean;
  name?: string;
}): DerivedWallet {
  const {
    mnemonic,
    network,
    derivationPath = DEFAULT_DERIVATION_PATH,
    isImported = false,
    name,
  } = params;

  const hdWallet = HDNodeWallet.fromPhrase(mnemonic, undefined, derivationPath);
  const walletEntity = createWallet({
    name,
    address: hdWallet.address,
    network,
    isImported,
  });

  return {
    wallet: walletEntity,
    hdWallet,
    privateKey: hdWallet.privateKey,
    mnemonic,
  };
}
