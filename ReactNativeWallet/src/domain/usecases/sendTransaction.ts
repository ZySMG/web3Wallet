import { Interface } from 'ethers';
import type { Wallet } from '@domain/entities/Wallet';
import type { Currency } from '@domain/entities/Currency';
import type { GasEstimate } from '@domain/entities/GasEstimate';
import { toRawAmount } from '@common/utils/eth';
import {
  getRecommendedFeeData,
  getNonce,
  sendRawTransaction,
} from '@data/services/EthereumService';
import { WalletRepository } from '@domain/repositories/WalletRepository';
import { deriveWalletFromMnemonic } from '@domain/services/WalletDerivationService';

const ERC20_INTERFACE = new Interface([
  'function transfer(address to, uint256 amount) returns (bool)',
]);

export async function sendTransaction(params: {
  repository: WalletRepository;
  wallet: Wallet;
  to: string;
  amount: string;
  currency: Currency;
  gasEstimate?: GasEstimate;
}): Promise<string> {
  const { repository, wallet, to, amount, currency, gasEstimate } = params;

  const mnemonic = await repository.getMnemonic(wallet);
  if (!mnemonic) {
    throw new Error('Mnemonic not found for the selected wallet');
  }

  const { hdWallet } = deriveWalletFromMnemonic({
    mnemonic,
    network: wallet.network,
    isImported: wallet.isImported,
    name: wallet.name,
  });

  const feeData = gasEstimate
    ? {
        gasPriceWei: gasEstimate.gasPriceWei,
        maxFeePerGasWei: gasEstimate.maxFeePerGasWei,
        maxPriorityFeePerGasWei: gasEstimate.maxPriorityFeePerGasWei,
      }
    : await getRecommendedFeeData(wallet.network);

  const gasLimit = gasEstimate?.gasLimit ?? BigInt(21000);
  const nonce = await getNonce(wallet.address, wallet.network);

  const amountRaw = toRawAmount(amount, currency.decimals);

  const baseTx = {
    chainId: wallet.network.chainId,
    gasLimit,
    nonce,
  };

  const transactionRequest = currency.contractAddress
    ? {
        ...baseTx,
        to: currency.contractAddress,
        data: ERC20_INTERFACE.encodeFunctionData('transfer', [to, amountRaw]),
        value: BigInt(0),
      }
    : {
        ...baseTx,
        to,
        value: amountRaw,
      };

  if (
    feeData.maxFeePerGasWei !== undefined &&
    feeData.maxPriorityFeePerGasWei !== undefined
  ) {
    Object.assign(transactionRequest, {
      maxFeePerGas: feeData.maxFeePerGasWei,
      maxPriorityFeePerGas: feeData.maxPriorityFeePerGasWei,
    });
  } else {
    Object.assign(transactionRequest, {
      gasPrice: feeData.gasPriceWei,
    });
  }

  const signedTx = await hdWallet.signTransaction(transactionRequest);
  return sendRawTransaction(signedTx, wallet.network);
}
