//
//  DerivationService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import WalletCore
import RxSwift

/// Derivation rule
enum DerivationRule: String, CaseIterable {
    case bip44 = "m/44'/60'/0'/0"
    case bip49 = "m/49'/60'/0'/0"
    case bip84 = "m/84'/60'/0'/0"
    
    var displayName: String {
        switch self {
        case .bip44: return "BIP44 (Legacy)"
        case .bip49: return "BIP49 (P2SH)"
        case .bip84: return "BIP84 (Native SegWit)"
        }
    }
    
    var coinType: Int {
        return 60 // Ethereum's coin type
    }
}

/// Account entity
struct Account: Codable, Equatable {
    let id: String
    let walletId: String
    let address: String
    let derivationPath: String
    let index: Int
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         walletId: String,
         address: String,
         derivationPath: String,
         index: Int,
         createdAt: Date = Date()) {
        self.id = id
        self.walletId = walletId
        self.address = address
        self.derivationPath = derivationPath
        self.index = index
        self.createdAt = createdAt
    }
}

/// Derivation service protocol
protocol DerivationServiceProtocol {
    /// Derive private key from seed
    func derivePrivateKey(from seed: Data, path: String) -> Data?
    
    /// Derive address from private key
    func deriveAddress(from privateKey: Data, coinType: Int) -> String?
    
    /// Derive address from seed (convenience method)
    func deriveAddressFromSeed(from seed: Data, coinType: Int) -> String?
    
    /// Generate derivation path
    func generateDerivationPath(coinType: Int, accountIndex: Int) -> String
    
    /// Derive multiple accounts
    func deriveAccounts(from seed: Data, walletId: String, derivationRule: DerivationRule, maxIndex: Int) -> [Account]
}

/// 派生服务实现
class DerivationService: DerivationServiceProtocol {
    
    func derivePrivateKey(from seed: Data, path: String) -> Data? {
        // 使用 TrustWalletCore 进行 BIP32 派生
        guard let hdWallet = HDWallet(entropy: seed, passphrase: "") else {
            Logger.error("Failed to create HD wallet from seed")
            return nil
        }
        
        let privateKey = hdWallet.getKey(coin: CoinType.ethereum, derivationPath: path)
        
        return privateKey.data
    }
    
    func deriveAddressFromSeed(from seed: Data, coinType: Int) -> String? {
        guard coinType == 60 else {
            Logger.error("Unsupported coin type: \(coinType)")
            return nil
        }
        
        // Create HDWallet from seed (seed is already derived from mnemonic)
        guard let hdWallet = HDWallet(entropy: seed, passphrase: "") else {
            Logger.error("Failed to create HDWallet from seed")
            return nil
        }
        
        // Derive private key using Ethereum derivation path
        let derivationPath = "m/44'/60'/0'/0/0"
        let privateKey = hdWallet.getKey(coin: CoinType.ethereum, derivationPath: derivationPath)
        
        // Derive address from private key
        guard let privateKeyObj = PrivateKey(data: privateKey.data) else {
            Logger.error("Failed to create private key object")
            return nil
        }
        
        let publicKey = privateKeyObj.getPublicKeySecp256k1(compressed: false)
        let address = AnyAddress(publicKey: publicKey, coin: CoinType.ethereum)
        
        return address.description
    }
    
    func deriveAddress(from privateKey: Data, coinType: Int) -> String? {
        guard coinType == 60 else {
            Logger.error("Unsupported coin type: \(coinType)")
            return nil
        }
        
        // 使用 TrustWalletCore 派生以太坊地址
        guard let privateKeyObj = PrivateKey(data: privateKey) else {
            Logger.error("Failed to create private key object")
            return nil
        }
        
        let publicKey = privateKeyObj.getPublicKeySecp256k1(compressed: false)
        
        let address = AnyAddress(publicKey: publicKey, coin: CoinType.ethereum)
        
        return address.description
    }
    
    func generateDerivationPath(coinType: Int, accountIndex: Int) -> String {
        return "m/44'/\(coinType)'/0'/0/\(accountIndex)"
    }
    
    func deriveAccounts(from seed: Data, walletId: String, derivationRule: DerivationRule, maxIndex: Int) -> [Account] {
        var accounts: [Account] = []
        
        for index in 0...maxIndex {
            let path = generateDerivationPath(coinType: derivationRule.coinType, accountIndex: index)
            
            guard let privateKey = derivePrivateKey(from: seed, path: path),
                  let address = deriveAddress(from: privateKey, coinType: derivationRule.coinType) else {
                Logger.error("Failed to derive account at index \(index)")
                continue
            }
            
            let account = Account(
                walletId: walletId,
                address: address,
                derivationPath: path,
                index: index
            )
            
            accounts.append(account)
        }
        
        return accounts
    }
}

/// 账户发现服务
class AccountDiscoveryService {
    private let ethereumService: EthereumServiceProtocol
    private let gapLimit: Int
    
    init(ethereumService: EthereumServiceProtocol, gapLimit: Int = 20) {
        self.ethereumService = ethereumService
        self.gapLimit = gapLimit
    }
    
    /// 发现新账户（检查后续索引是否有余额或交易）
    func discoverAccounts(from seed: Data, walletId: String, derivationRule: DerivationRule, currentMaxIndex: Int) -> Observable<Int> {
        return Observable.create { observer in
            let derivationService = DerivationService()
            var newMaxIndex = currentMaxIndex
            var consecutiveEmptyAccounts = 0
            
            for index in (currentMaxIndex + 1)...(currentMaxIndex + self.gapLimit) {
                let path = derivationService.generateDerivationPath(coinType: derivationRule.coinType, accountIndex: index)
                
                guard let privateKey = derivationService.derivePrivateKey(from: seed, path: path),
                      let address = derivationService.deriveAddress(from: privateKey, coinType: derivationRule.coinType) else {
                    continue
                }
                
                // 检查地址是否有余额或交易
                self.checkAccountActivity(address: address, network: .ethereumMainnet)
                    .subscribe(onNext: { hasActivity in
                        if hasActivity {
                            newMaxIndex = max(newMaxIndex, index)
                            consecutiveEmptyAccounts = 0
                        } else {
                            consecutiveEmptyAccounts += 1
                        }
                        
                        // 如果连续多个空账户，停止发现
                        if consecutiveEmptyAccounts >= 5 {
                            observer.onNext(newMaxIndex)
                            observer.onCompleted()
                        }
                    }, onError: { error in
                        observer.onError(error)
                    })
                    .disposed(by: DisposeBag())
            }
            
            observer.onNext(newMaxIndex)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    private func checkAccountActivity(address: String, network: Network) -> Observable<Bool> {
        // 检查 ETH 余额
        let ethBalance = ethereumService.getBalance(address: address, currency: .eth, network: network)
        
        // 检查是否有交易历史（这里简化处理，实际应该调用交易历史 API）
        let hasTransactions = Observable.just(false) // TODO: 实现交易历史检查
        
        return Observable.combineLatest(ethBalance, hasTransactions) { balance, hasTx in
            return balance > 0 || hasTx
        }
    }
}
