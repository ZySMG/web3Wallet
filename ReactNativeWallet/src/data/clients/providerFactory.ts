import { JsonRpcProvider } from 'ethers';
import type { Network } from '@domain/entities/Network';

const providerCache = new Map<number, JsonRpcProvider>();

export function getRpcProvider(network: Network): JsonRpcProvider {
  if (providerCache.has(network.chainId)) {
    return providerCache.get(network.chainId)!;
  }
  const provider = new JsonRpcProvider(network.rpcUrl, network.chainId);
  providerCache.set(network.chainId, provider);
  return provider;
}
