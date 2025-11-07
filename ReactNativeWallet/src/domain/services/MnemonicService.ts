import { HDNodeWallet, Wallet } from 'ethers';

export function generateMnemonic(): string {
  const hdWallet = Wallet.createRandom() as HDNodeWallet;
  return hdWallet.mnemonic?.phrase ?? '';
}

export function validateMnemonic(mnemonic: string): boolean {
  try {
    HDNodeWallet.fromPhrase(mnemonic);
    return true;
  } catch {
    return false;
  }
}
