export type GasEstimate = {
  gasLimit: bigint;
  gasPriceWei: bigint;
  maxFeePerGasWei?: bigint;
  maxPriorityFeePerGasWei?: bigint;
  feeWei: bigint;
};

export function createGasEstimate(params: {
  gasLimit: bigint | number | string;
  gasPriceWei: bigint | number | string;
  maxFeePerGasWei?: bigint | number | string;
  maxPriorityFeePerGasWei?: bigint | number | string;
}): GasEstimate {
  const gasLimit = BigInt(params.gasLimit);
  const gasPriceWei = BigInt(params.gasPriceWei);
  const maxFeePerGasWei =
    params.maxFeePerGasWei !== undefined
      ? BigInt(params.maxFeePerGasWei)
      : undefined;
  const maxPriorityFeePerGasWei =
    params.maxPriorityFeePerGasWei !== undefined
      ? BigInt(params.maxPriorityFeePerGasWei)
      : undefined;
  const feeReferenceWei = maxFeePerGasWei ?? gasPriceWei;
  const feeWei = feeReferenceWei * gasLimit;

  return {
    gasLimit,
    gasPriceWei,
    maxFeePerGasWei,
    maxPriorityFeePerGasWei,
    feeWei,
  };
}
