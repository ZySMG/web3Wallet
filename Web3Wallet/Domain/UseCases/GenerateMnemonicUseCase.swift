//
//  GenerateMnemonicUseCase.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import WalletCore

/// Generate mnemonic use case
/// Responsible for generating new mnemonic phrases and corresponding wallet addresses
protocol GenerateMnemonicUseCaseProtocol {
    func generateMnemonic() -> Observable<String>
    func generateWallet(from mnemonic: String, network: Network) -> Observable<Wallet>
}

class GenerateMnemonicUseCase: GenerateMnemonicUseCaseProtocol {
    
    private let derivationService: DerivationServiceProtocol
    private let mnemonicValidator: MnemonicValidatorProtocol
    
    init(derivationService: DerivationServiceProtocol = DerivationService(),
         mnemonicValidator: MnemonicValidatorProtocol = MnemonicValidator()) {
        self.derivationService = derivationService
        self.mnemonicValidator = mnemonicValidator
    }
    
    func generateMnemonic() -> Observable<String> {
        return Observable.create { observer in
            do {
                // Generate real mnemonic using WalletCore
                guard let hdWallet = HDWallet(strength: 128, passphrase: "") else {
                    observer.onError(WalletError.unknown)
                    return Disposables.create()
                }
                let mnemonic = hdWallet.mnemonic
                observer.onNext(mnemonic)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
    
    func generateWallet(from mnemonic: String, network: Network) -> Observable<Wallet> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            do {
                // Validate mnemonic using the same validator as ImportWalletUseCase
                guard self.mnemonicValidator.isValid(mnemonic) else {
                    observer.onError(WalletError.invalidMnemonic)
                    return Disposables.create()
                }
                
                // Create HDWallet directly from mnemonic
                guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
                    observer.onError(WalletError.invalidMnemonic)
                    return Disposables.create()
                }
                
                // Derive Ethereum address directly - always use index 0 for consistency
                let derivationPath = "m/44'/60'/0'/0/0"
                let privateKey = hdWallet.getKey(coin: CoinType.ethereum, derivationPath: derivationPath)
                
                // Create address from private key
                guard let privateKeyObj = PrivateKey(data: privateKey.data) else {
                    observer.onError(WalletError.invalidAddress)
                    return Disposables.create()
                }
                
                let publicKey = privateKeyObj.getPublicKeySecp256k1(compressed: false)
                let address = AnyAddress(publicKey: publicKey, coin: CoinType.ethereum)
                
                let wallet = Wallet(
                    address: address.description,
                    network: network,
                    isImported: false,
                    fingerprint: address.description
                )
                
                // ✅ Save mnemonic to Keychain
                let keychainStorage = KeychainStorageService()
                _ = keychainStorage.store(key: "mnemonic_\(address.description)", value: mnemonic)
                
                observer.onNext(wallet)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}

/// Wallet-related errors
enum WalletError: Error, LocalizedError {
    case invalidMnemonic
    case invalidAddress
    case walletNotFound
    case keychainError
    case networkError(String)
    case transactionCreationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidMnemonic:
            return "Invalid mnemonic phrase"
        case .invalidAddress:
            return "Invalid wallet address"
        case .walletNotFound:
            return "Wallet not found"
        case .keychainError:
            return "Keychain operation failed"
        case .networkError(let message):
            return message
        case .transactionCreationFailed:
            return "Failed to create transaction"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}
