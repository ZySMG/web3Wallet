import type { Network } from './Network';

export type Wallet = {
  id: string;
  name: string;
  address: string;
  network: Network;
  createdAt: string;
  isImported: boolean;
  fingerprint: string;
};

export function createWallet(params: {
  id?: string;
  name?: string;
  address: string;
  network: Network;
  createdAt?: string;
  isImported?: boolean;
  fingerprint?: string;
}): Wallet {
  const {
    id = `wallet_${Date.now().toString(16)}_${Math.random()
      .toString(16)
      .slice(2, 8)}`,
    name = '',
    address,
    network,
    createdAt = new Date().toISOString(),
    isImported = false,
    fingerprint,
  } = params;

  return {
    id,
    name,
    address,
    network,
    createdAt,
    isImported,
    fingerprint: fingerprint ?? address.toLowerCase(),
  };
}

export function formatAddress(address: string, length = 4): string {
  if (address.length <= length * 2) {
    return address;
  }
  return `${address.slice(0, length + 2)}…${address.slice(-length)}`;
}
