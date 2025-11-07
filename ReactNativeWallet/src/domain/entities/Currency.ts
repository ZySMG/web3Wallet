export type Currency = {
  symbol: string;
  name: string;
  decimals: number;
  contractAddress?: string;
};

const ETH: Currency = {
  symbol: 'ETH',
  name: 'Ethereum',
  decimals: 18,
};

const USDC: Currency = {
  symbol: 'USDC',
  name: 'USD Coin',
  decimals: 6,
  contractAddress: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
};

const USDT: Currency = {
  symbol: 'USDT',
  name: 'Tether USD (Testnet)',
  decimals: 6,
  contractAddress: '0xb38e0ba5aea889652b64ad38d624848896dcb089',
};

export const CURRENCIES = {
  eth: ETH,
  usdc: USDC,
  usdt: USDT,
} as const;

export const SUPPORTED_CURRENCIES: Currency[] = [
  CURRENCIES.eth,
  CURRENCIES.usdc,
  CURRENCIES.usdt,
];

export function isNativeCurrency(currency: Currency): boolean {
  return !currency.contractAddress;
}
