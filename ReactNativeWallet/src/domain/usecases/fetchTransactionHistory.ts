import type { Wallet } from '@domain/entities/Wallet';
import type { Transaction } from '@domain/entities/Transaction';
import { EtherscanService } from '@data/services/EtherscanService';

export async function fetchTransactionHistory(params: {
  etherscanService: EtherscanService;
  wallet: Wallet;
  limit?: number;
}): Promise<Transaction[]> {
  const { etherscanService, wallet, limit } = params;
  return etherscanService.getTransactions(wallet.address, wallet.network, limit);
}
