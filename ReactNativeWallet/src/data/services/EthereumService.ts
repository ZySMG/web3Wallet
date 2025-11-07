import type { Network } from '@domain/entities/Network';
import { getRpcProvider } from '../clients/providerFactory';

export async function getNonce(
  address: string,
  network: Network,
): Promise<number> {
  const provider = getRpcProvider(network);
  return provider.getTransactionCount(address, 'latest');
}

export type RecommendedFeeData = {
  gasPriceWei: bigint;
  maxFeePerGasWei?: bigint;
  maxPriorityFeePerGasWei?: bigint;
};

export async function getRecommendedFeeData(
  network: Network,
): Promise<RecommendedFeeData> {
  const provider = getRpcProvider(network);
  const feeData = await provider.getFeeData();
  const baseFee = feeData.lastBaseFeePerGas ?? feeData.gasPrice ?? feeData.maxFeePerGas;
  const minPriority = BigInt(1_000_000_000); // 1 gwei

  const gasPriceCandidate = feeData.gasPrice ?? feeData.maxFeePerGas;
  if (!gasPriceCandidate || !baseFee) {
    throw new Error('Unable to fetch gas price');
  }
  let maxPriorityFeePerGasWei =
    feeData.maxPriorityFeePerGas ?? minPriority;
  if (maxPriorityFeePerGasWei < minPriority) {
    maxPriorityFeePerGasWei = minPriority;
  }

  let maxFeePerGasWei =
    feeData.maxFeePerGas ?? baseFee + maxPriorityFeePerGasWei;
  if (maxFeePerGasWei < baseFee + maxPriorityFeePerGasWei) {
    maxFeePerGasWei = baseFee + maxPriorityFeePerGasWei;
  }

  const legacyGasPriceWei = feeData.gasPrice ?? maxFeePerGasWei;

  return {
    gasPriceWei: legacyGasPriceWei,
    maxFeePerGasWei,
    maxPriorityFeePerGasWei,
  };
}

export async function estimateGasLimit(
  network: Network,
  tx: {
    from: string;
    to: string;
    valueWei?: bigint;
    data?: string;
  },
): Promise<bigint> {
  const provider = getRpcProvider(network);
  const request = {
    from: tx.from,
    to: tx.to,
    value: tx.valueWei,
    data: tx.data,
  };

  return provider.estimateGas(request);
}

export async function sendRawTransaction(
  rawTransaction: string,
  network: Network,
): Promise<string> {
  const provider = getRpcProvider(network);
  const response = await provider.broadcastTransaction(rawTransaction);
  return response.hash;
}
