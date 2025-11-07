import type { Currency } from './Currency';

export type Balance = {
  currency: Currency;
  amount: string;
  rawAmount: string;
  usdValue?: number;
  lastUpdated: string;
};

export function createBalance(params: {
  currency: Currency;
  amount: string;
  rawAmount: string;
  usdValue?: number;
  lastUpdated?: string;
}): Balance {
  const { currency, amount, rawAmount, usdValue, lastUpdated } = params;
  return {
    currency,
    amount,
    rawAmount,
    usdValue,
    lastUpdated: lastUpdated ?? new Date().toISOString(),
  };
}
