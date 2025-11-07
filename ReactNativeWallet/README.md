# Web3 Wallet · React Native

A React Native port of the iOS Web3 Wallet. The app targets the Ethereum Sepolia testnet, mirroring the Clean Architecture layers (App → Domain → Data → Presentation) from the Swift implementation while adopting idiomatic React patterns.

## Features

- 🔐 **Wallet lifecycle** – create or import HD wallets (BIP-44 `m/44'/60'/0'/0/0`), mnemonic validation, secure mnemonic storage powered by `react-native-keychain`.
- 💰 **Portfolio overview** – ETH, USDC, USDT balances with USD valuation, cached Etherscan lookups, pull-to-refresh, and clipboard shortcuts.
- 📜 **Activity feed** – merged native and ERC-20 history, explorer deep-links, optimistic status badges.
- 💸 **Send & Receive** – ERC-20 + native ETH transfers via `ethers v6`, automatic gas estimation, QR-based receive flow.
- 🔄 **State management** – Zustand store orchestrates repositories, use-cases, and view state, mirroring the RxSwift pipelines in the iOS project.
- 🧪 **Tooling** – TypeScript, ESLint, Jest, React Query, React Navigation, Reanimated (new architecture ready).

## Project layout

```
ReactNativeWallet/
├── src/
│   ├── app/              # Providers, navigation, DI container
│   ├── domain/           # Entities, services, use cases, repositories
│   ├── data/             # API clients, storage adapters, infrastructure services
│   ├── presentation/     # Screens, components, Zustand store
│   └── common/           # Constants and cross-cutting utilities
├── ios/ & android/       # Native projects (autolinked pods / gradle modules)
├── jest.setup.js         # Testing shims for RN modules
└── README.md             # This guide
```

## Prerequisites

- Node.js ≥ 20 (CLI template ships with this constraint)
- Xcode 15 / Android Studio Iguana (or newer)
- CocoaPods 1.12+

Optional but recommended:
- Etherscan API key (set in `src/app/config/env.ts`)
- CoinGecko API key (for higher rate limits)

## Quick start

Install JS dependencies and native pods:

```sh
npm install
npx pod-install ios
```

Run type checks, lint, and Jest before booting the app:

```sh
npm run typecheck
npm run lint
npm test
```

Start Metro in one terminal:

```sh
npm start
```

Then launch the app:

```sh
npm run ios   # or npm run android
```

> **Tip:** The project opts into the new React Native architecture; if you encounter native build errors, run `npx react-native clean-project` and reinstall pods.

## Configuration

Default environment settings live in `src/app/config/env.ts`:

```ts
export const ENV = {
  ETHERSCAN_API_KEY: 'YourApiKeyToken',
  COINGECKO_API_KEY: '',
};
```

Replace the placeholders with your keys. Sepolia accounts continue to work with the default public token, albeit with stricter rate limits.

### Test data

Use the following mnemonic (mirrors the iOS README) to bootstrap a funded Sepolia wallet:

```
abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

Address: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb`

## Scripts

| Command | Description |
| --- | --- |
| `npm start` | Run Metro bundler |
| `npm run ios` / `npm run android` | Build & launch native apps |
| `npm run lint` / `npm run lint:fix` | ESLint checks |
| `npm run typecheck` | TypeScript compilation in watchless mode |
| `npm test` | Jest + React Native mocks |

## Testing notes

Jest is configured to mock common RN modules (`AsyncStorage`, `Clipboard`, `react-native-reanimated`, QR code rendering). If you add native dependencies, extend `jest.setup.js` and `transformIgnorePatterns` as needed.

## Outstanding work

- Hook up production-ready price aggregation (currently single-source CoinGecko)
- Add UI flows for mnemonic confirmation & wallet deletion
- Extend unit coverage around Zustand store and use-cases

Migrating additional Swift use-cases should now be straightforward: implement the data service inside `src/data`, expose a domain use-case, wire it through the Zustand store, and surface it in the screen layer.
