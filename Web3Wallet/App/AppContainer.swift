//
//  AppContainer.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Application container
/// Responsible for dependency injection and service creation
class AppContainer {
    
    // MARK: - Services
    lazy var networkService: NetworkServiceProtocol = {
        return NetworkService()
    }()
    
    lazy var keychainStorage: KeychainStorageServiceProtocol = {
        return KeychainStorageService()
    }()
    
    lazy var preferencesStorage: PreferencesStorageServiceProtocol = {
        return PreferencesStorageService()
    }()
    
    lazy var cacheService: CacheServiceProtocol = {
        return CacheService()
    }()
    
    lazy var networkStatusService: NetworkStatusService = {
        return NetworkStatusService.shared
    }()
    
    lazy var ethereumService: EthereumServiceProtocol = {
        let etherscanV2Service = EtherscanV2Service(
            apiKey: APIKeys.etherscanSepoliaKey,
            chainId: "11155111", // Sepolia chain ID
            baseURL: "https://api.etherscan.io/v2/api"
        )
        return EthereumService(etherscan: etherscanV2Service)
    }()
    
    lazy var tokenService: TokenServiceProtocol = {
        return TokenService(networkService: networkService)
    }()
    
    lazy var txService: TxServiceProtocol = {
        return TxService(networkService: networkService)
    }()
    
    lazy var priceService: PriceServiceProtocol = {
        return MultiSourcePriceService(networkService: networkService)
    }()
    
    // MARK: - Use Cases
    lazy var generateMnemonicUseCase: GenerateMnemonicUseCaseProtocol = {
        return GenerateMnemonicUseCase()
    }()
    
    lazy var importWalletUseCase: ImportWalletUseCaseProtocol = {
        return ImportWalletUseCase(mnemonicValidator: mnemonicValidator)
    }()
    
    lazy var resolveBalancesUseCase: ResolveBalancesUseCaseProtocol = {
        return ResolveBalancesUseCase(
            ethereumService: ethereumService,
            cacheService: cacheService
        )
    }()
    
    lazy var fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol = {
        return FetchTxHistoryUseCase(
            txService: txService,
            cacheService: cacheService
        )
    }()
    
    lazy var estimateGasUseCase: EstimateGasUseCaseProtocol = {
        return EstimateGasUseCase()
    }()
    
    // MARK: - Validators
    lazy var mnemonicValidator: MnemonicValidatorProtocol = {
        return MnemonicValidator()
    }()
    
    lazy var addressValidator: AddressValidatorProtocol = {
        return AddressValidator()
    }()
    
    // MARK: - Current Wallet
    var currentWallet: Wallet? {
        get {
            guard let walletString = keychainStorage.retrieve(key: "current_wallet"),
                  let walletData = walletString.data(using: .utf8) else {
                return nil
            }
            
            return try? JSONDecoder().decode(Wallet.self, from: walletData)
        }
        set {
            if let wallet = newValue {
                do {
                    let walletData = try JSONEncoder().encode(wallet)
                    let walletString = String(data: walletData, encoding: .utf8) ?? ""
                    keychainStorage.store(key: "current_wallet", value: walletString)
                } catch {
                    Logger.error("Failed to save current wallet: \(error)")
                }
            } else {
                keychainStorage.delete(key: "current_wallet")
            }
        }
    }
    
    // MARK: - Current Network
    var currentNetwork: Network {
        get {
            guard let networkData = preferencesStorage.retrieve(key: StorageKeys.selectedNetwork, type: Network.self) else {
                return Network.sepolia // Default to testnet
            }
            return networkData
        }
        set {
            preferencesStorage.store(key: StorageKeys.selectedNetwork, value: newValue)
        }
    }
}
