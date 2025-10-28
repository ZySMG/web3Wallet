//
//  ImportWalletUseCase.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import WalletCore

/// 导入钱包用例
/// 负责从助记词导入现有钱包
protocol ImportWalletUseCaseProtocol {
    func importWallet(from mnemonic: String, network: Network) -> Observable<Wallet>
}

class ImportWalletUseCase: ImportWalletUseCaseProtocol {
    
    private let mnemonicValidator: MnemonicValidatorProtocol
    private let derivationService: DerivationServiceProtocol
    
    init(mnemonicValidator: MnemonicValidatorProtocol = MnemonicValidator(), 
         derivationService: DerivationServiceProtocol = DerivationService()) {
        self.mnemonicValidator = mnemonicValidator
        self.derivationService = derivationService
    }
    
    func importWallet(from mnemonic: String, network: Network) -> Observable<Wallet> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // Validate mnemonic
            guard self.mnemonicValidator.isValid(mnemonic) else {
                observer.onError(WalletError.invalidMnemonic)
                return Disposables.create()
            }
            
            do {
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
                    isImported: true,
                    fingerprint: address.description
                )
                
                // ✅ 保存助记词到Keychain
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
