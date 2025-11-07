import { CURRENCIES } from './Currency';

export type Network = {
  id: string;
  name: string;
  chainId: number;
  rpcUrl: string;
  explorerBaseUrl: string;
  nativeCurrency: typeof CURRENCIES.eth;
  isTestnet: boolean;
};

const ETHEREUM_MAINNET: Network = {
  id: 'ethereum_mainnet',
  name: 'Ethereum Mainnet',
  chainId: 1,
  rpcUrl: 'https://mainnet.infura.io/v3/1b7ed1f23d854cd99b816a1b6ea27b12',
  explorerBaseUrl: 'https://etherscan.io',
  nativeCurrency: CURRENCIES.eth,
  isTestnet: false,
};

const SEPOLIA_TESTNET: Network = {
  id: 'sepolia',
  name: 'Sepolia Testnet',
  chainId: 11155111,
  rpcUrl: 'https://sepolia.infura.io/v3/1b7ed1f23d854cd99b816a1b6ea27b12',
  explorerBaseUrl: 'https://sepolia.etherscan.io',
  nativeCurrency: CURRENCIES.eth,
  isTestnet: true,
};

export const NETWORKS = {
  ethereumMainnet: ETHEREUM_MAINNET,
  sepolia: SEPOLIA_TESTNET,
} as const;

export const SUPPORTED_NETWORKS: Network[] = [
  NETWORKS.ethereumMainnet,
  NETWORKS.sepolia,
];
