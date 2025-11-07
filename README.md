# Web3Wallet

A modern iOS Web3 wallet application built with UIKit, RxSwift, and TrustWalletCore, supporting Ethereum mainnet and testnet operations.

## 🚀 Quick Start

### Prerequisites
- Xcode 15.0+
- iOS 15.0+
- CocoaPods

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd trust_wallet2
   ```

2. **Install dependencies**
   ```bash
   pod install
   ```

3. **Open the workspace**
   ```bash
   open trust_wallet2.xcworkspace
   ```

4. **Build and run**
   - Select iPhone simulator or device
   - Press `Cmd + R` to build and run

### ⚠️ Important Notes

- **Always use `.xcworkspace`** file, not `.xcodeproj`
- **Run `pod install`** after any Podfile changes
- **Clean build folder** (`Cmd + Shift + K`) if you encounter build issues
- **Test on Sepolia testnet** first before using mainnet

## 📱 Features Overview

### Core Functionality
- 🔐 **Wallet Management**: Create/import mnemonic wallets with EIP-55 address format
- 💰 **Asset Management**: Support ETH, USDC, USDT balance queries with USD equivalent display
- 📊 **Transaction History**: View transaction records and details with Explorer links
- 💸 **Send Transactions**: Transaction forms with gas estimation and real blockchain broadcasting
- 🌐 **Multi-Network**: Support Ethereum mainnet and Sepolia testnet
- 🔄 **Real-time Updates**: Pull-to-refresh and foreground wake-up auto-updates
- 📱 **Reactive UI**: MVVM architecture based on RxSwift

### Technical Highlights
- **Clean Architecture**: Coordinator + MVVM pattern
- **Reactive Programming**: RxSwift + RxCocoa for responsive UI
- **Security**: Keychain storage for sensitive data (mnemonics, private keys)
- **Network Layer**: Etherscan V2 API integration with fallback mechanisms
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **State Management**: Singleton-based wallet state synchronization

## 🏗️ Project Architecture

### Architecture Pattern
The project follows **Clean Architecture** principles with clear separation of concerns:

- **Presentation Layer**: UI components, ViewModels, and Coordinators
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: Network services, storage, and external API integrations

### Key Components
- **Coordinators**: Handle navigation flow and dependency injection
- **ViewModels**: Business logic and reactive data binding
- **Use Cases**: Encapsulate specific business operations
- **Services**: Handle external dependencies (APIs, storage, etc.)

### State Management
- **WalletManagerSingleton**: Centralized wallet state management
- **Reactive Streams**: RxSwift observables for real-time updates
- **Keychain Integration**: Secure storage for sensitive wallet data

For detailed architecture information, see [ARCHITECTURE_SUMMARY_EN.md](ARCHITECTURE_SUMMARY_EN.md)

## 📁 Project Structure

### Directory Organization
```
Web3Wallet/
├── App/                    # Application entry and coordinators
├── Common/                 # Shared components and utilities
│   ├── Extensions/        # Swift extensions
│   ├── Utilities/         # Utility classes (Logger, EIP55, QRCode)
│   └── UI/               # Reusable UI components
├── Data/                  # Data layer
│   ├── Network/          # Network services and API clients
│   ├── Ethereum/         # Ethereum-specific services
│   ├── Storage/          # Storage services (Keychain, UserDefaults)
│   ├── Price/            # Price data services
│   └── Cache/            # Caching mechanisms
├── Domain/                # Domain layer
│   ├── Entities/         # Core business entities
│   ├── UseCases/         # Business use cases
│   ├── Services/         # Domain services
│   └── Validation/       # Input validation
├── Presentation/          # Presentation layer
│   ├── Coordinators/     # Navigation coordinators
│   ├── Scenes/          # UI scenes and ViewModels
│   └── Components/       # UI components
└── Resources/             # Resources and assets
    ├── Localizable.strings
    └── Mocks/           # Mock data for testing
```

### File Organization Principles
- **Feature-based grouping**: Related functionality grouped together
- **Layer separation**: Clear boundaries between presentation, domain, and data layers
- **Reusable components**: Shared utilities and UI components in Common/
- **Test organization**: Mirror structure in test directories

For complete directory structure details, see [DIRECTORY_STRUCTURE_EN.md](DIRECTORY_STRUCTURE_EN.md)

## 🔧 Configuration

### API Configuration (Optional)
The app can run without API keys using mock data, but for full functionality:

1. **Etherscan API**: Get free API key from [etherscan.io](https://etherscan.io/apis)
2. **CoinGecko API**: Get free API key from [coingecko.com](https://coingecko.com/en/api)

### Network Configuration
- **Mainnet**: Ethereum mainnet (Chain ID: 1) - **Under Development**
- **Testnet**: Sepolia testnet (Chain ID: 11155111) - **Fully Supported**

### Test Data
Use these test credentials for Sepolia testnet:

**Test Mnemonic:**
```
abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

**Test Address:**
```
0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
```

## 🧪 Testing

The project ships with a hostless **Web3WalletTests** target covering ViewModel logic, mnemonic workflows, and network/service stubs. Tests run entirely in the simulator so no host application is required.

### Running Tests
```bash
xcodebuild test \
  -workspace trust_wallet2.xcworkspace \
  -scheme trust_wallet2 \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' \
  -only-testing:Web3WalletTests
```

> 💡 When running on a physical device, configure the Web3WalletTests target with a Test Host (`$(BUILT_PRODUCTS_DIR)/trust_wallet2.app/trust_wallet2`). The default hostless setup is optimized for simulator runs.

### Test Coverage
- **ViewModel Tests**: Covers send, receive, welcome, wallet home, and other MVVM flows
- **Mnemonic & Validator Tests**: Verifies mnemonic generation, import, and validation logic
- **Network Stubs**: Provides deterministic data for balances, transaction history, and prices

## 🔒 Security Features

### Data Protection
- **Keychain Storage**: Sensitive data stored with `ThisDeviceOnly` access
- **No Logging**: Sensitive information never appears in logs
- **Secure Derivation**: BIP44 standard derivation paths
- **Private Key Isolation**: Private keys never stored in plain text

### Network Security
- **HTTPS Only**: All API communications over secure connections
- **API Key Protection**: API keys stored securely in Keychain
- **Rate Limiting**: Built-in protection against API abuse

## 🚨 Troubleshooting

### Common Issues

**Build Errors:**
```bash
# Clean and rebuild
Cmd + Shift + K  # Clean build folder
Cmd + B          # Build project
```

**Pod Installation Issues:**
```bash
# Update CocoaPods
sudo gem install cocoapods
pod repo update
pod install
```

**Simulator Issues:**
- Reset simulator: Device → Erase All Content and Settings
- Restart Xcode if simulator becomes unresponsive

### Debug Mode
Enable debug logging by setting `DEBUG` flag in build settings.

## 📚 Additional Documentation

- **[ARCHITECTURE_SUMMARY_EN.md](ARCHITECTURE_SUMMARY_EN.md)**: Detailed architecture overview, design patterns, and technical decisions
- **[DIRECTORY_STRUCTURE_EN.md](DIRECTORY_STRUCTURE_EN.md)**: Complete project structure breakdown and file organization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift style guidelines
- Write unit tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For questions, issues, or suggestions:
- Create an issue in the repository
- Contact the development team
- Check the documentation in the linked markdown files

---

**Happy Coding! 🚀**
