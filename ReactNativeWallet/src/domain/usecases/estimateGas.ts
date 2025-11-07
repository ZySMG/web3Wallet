import type { Wallet } from '@domain/entities/Wallet';
import type { Currency } from '@domain/entities/Currency';
import { formatUnits, Interface } from 'ethers';
import { createGasEstimate, type GasEstimate } from '@domain/entities/GasEstimate';
import { estimateGasLimit, getRecommendedFeeData } from '@data/services/EthereumService';
import { toRawAmount } from '@common/utils/eth';

const ERC20_INTERFACE = new Interface([
  'function transfer(address to, uint256 amount) returns (bool)',
]);

export async function estimateGas(params: {
  wallet: Wallet;
  to: string;
  amount: string;
  currency: Currency;
  data?: string;
}): Promise<ReturnType<typeof createGasEstimate>> {
  const { wallet, to, amount, currency, data } = params;

  const feeData = await getRecommendedFeeData(wallet.network);

  const isTokenTransfer = Boolean(currency.contractAddress);
  const valueWei = isTokenTransfer ? undefined : toRawAmount(amount, currency.decimals);
  const encodedData =
    isTokenTransfer && amount
      ? ERC20_INTERFACE.encodeFunctionData('transfer', [
          to,
          toRawAmount(amount, currency.decimals),
        ])
      : data;

  const gasLimit = await estimateGasLimit(wallet.network, {
    from: wallet.address,
    to: currency.contractAddress ?? to,
    valueWei,
    data: encodedData,
  });

  return createGasEstimate({
    gasLimit,
    gasPriceWei: feeData.gasPriceWei,
    maxFeePerGasWei: feeData.maxFeePerGasWei,
    maxPriorityFeePerGasWei: feeData.maxPriorityFeePerGasWei,
  });
}

export function calculateFeeInEth(estimate: GasEstimate): string {
  return formatUnits(estimate.feeWei, 18);
}
