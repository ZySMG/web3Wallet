import type { Currency } from './Currency';
import type { Network } from './Network';

export type TransactionStatus = 'pending' | 'success' | 'failed';
export type TransactionDirection = 'inbound' | 'outbound';

export type Transaction = {
  hash: string;
  from: string;
  to: string;
  amount: string;
  currency: Currency;
  gasUsed?: string;
  gasPrice?: string;
  status: TransactionStatus;
  direction: TransactionDirection;
  timestamp: string;
  blockNumber?: string;
  network: Network;
};

export function formatTransactionAmount(
  tx: Transaction,
  showSymbol = true,
): string {
  const prefix = tx.direction === 'inbound' ? '+' : '-';
  const suffix = showSymbol ? ` ${tx.currency.symbol}` : '';
  return `${prefix}${tx.amount}${suffix}`;
}
