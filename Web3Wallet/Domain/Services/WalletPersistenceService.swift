//
//  WalletPersistenceService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// 模拟钱包存储服务
class MockWalletStore: WalletStoreProtocol {
    private var wallets: [Wallet] = []
    private var activeWalletId: String?
    
    var walletIndexSubject: BehaviorRelay<WalletIndex> = BehaviorRelay(value: WalletIndex())
    
    func getWalletIndex() -> WalletIndex {
        return WalletIndex(wallets: wallets, activeWalletId: activeWalletId)
    }
    
    func saveWalletIndex(_ index: WalletIndex) -> Bool {
        wallets = index.wallets
        activeWalletId = index.activeWalletId
        walletIndexSubject.accept(index)
        return true
    }
    
    func addWallet(_ wallet: Wallet) -> Bool {
        wallets.append(wallet)
        walletIndexSubject.accept(getWalletIndex())
        return true
    }
    
    func updateWallet(_ wallet: Wallet) -> Bool {
        if let index = wallets.firstIndex(where: { $0.id == wallet.id }) {
            wallets[index] = wallet
            walletIndexSubject.accept(getWalletIndex())
            return true
        }
        return false
    }
    
    func deleteWallet(walletId: String) -> Bool {
        wallets.removeAll { $0.id == walletId }
        if activeWalletId == walletId {
            activeWalletId = nil
        }
        walletIndexSubject.accept(getWalletIndex())
        return true
    }
    
    func setActiveWallet(walletId: String) -> Bool {
        if wallets.contains(where: { $0.id == walletId }) {
            activeWalletId = walletId
            walletIndexSubject.accept(getWalletIndex())
            return true
        }
        return false
    }
    
    func getActiveWallet() -> Wallet? {
        return wallets.first { $0.id == activeWalletId }
    }
    
    func getAllWallets() -> [Wallet] {
        return wallets
    }
    
    func isWalletExists(fingerprint: String) -> (exists: Bool, walletId: String?) {
        if let wallet = wallets.first(where: { $0.fingerprint == fingerprint }) {
            return (true, wallet.id)
        }
        return (false, nil)
    }
    
    func updateWalletMaxIndex(walletId: String, maxIndex: Int) -> Bool {
        return true
    }
}

/// 钱包持久化服务协议
protocol WalletPersistenceServiceProtocol {
    /// 保存钱包
    func saveWallet(_ wallet: Wallet) -> Observable<Bool>
    
    /// 获取所有钱包
    func getAllWallets() -> Observable<[Wallet]>
    
    /// 删除钱包
    func deleteWallet(walletId: String) -> Observable<Bool>
    
    /// 更新钱包
    func updateWallet(_ wallet: Wallet) -> Observable<Bool>
    
    /// 保存账户
    func saveAccount(_ account: Account) -> Observable<Bool>
    
    /// 获取钱包的所有账户
    func getAccounts(for walletId: String) -> Observable<[Account]>
    
    /// 删除账户
    func deleteAccount(accountId: String) -> Observable<Bool>
}

/// 钱包持久化服务实现
class WalletPersistenceService: WalletPersistenceServiceProtocol {
    
    private let walletStore: WalletStoreProtocol
    private let vaultService: VaultServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(walletStore: WalletStoreProtocol? = nil,
         vaultService: VaultServiceProtocol = VaultService(keychainService: KeychainStorageService(service: "Web3Wallet"))) {
        // 暂时使用模拟实现
        // TODO: 实现真实的 WalletStore 初始化
        self.walletStore = MockWalletStore()
        self.vaultService = vaultService
    }
    
    // MARK: - Wallet Operations
    
    func saveWallet(_ wallet: Wallet) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 保存到 WalletStore
            let success = self.walletStore.addWallet(wallet)
            observer.onNext(success)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func getAllWallets() -> Observable<[Wallet]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }
            
            let walletIndex = self.walletStore.getWalletIndex()
            observer.onNext(walletIndex.wallets)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func deleteWallet(walletId: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 从 WalletStore 删除
            let success = self.walletStore.deleteWallet(walletId: walletId)
            
            // 从 VaultService 删除加密数据
            _ = self.vaultService.deleteEncryptedWallet(walletId: walletId)
            
            observer.onNext(success)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func updateWallet(_ wallet: Wallet) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            let success = self.walletStore.updateWallet(wallet)
            observer.onNext(success)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    // MARK: - Account Operations
    
    func saveAccount(_ account: Account) -> Observable<Bool> {
        return Observable.create { observer in
            // 这里可以实现账户的持久化逻辑
            // 可以使用 UserDefaults、Core Data 或 SQLite
            // 目前使用简单的内存存储
            
            // TODO: 实现真实的持久化存储
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func getAccounts(for walletId: String) -> Observable<[Account]> {
        return Observable.create { observer in
            // TODO: 从持久化存储中获取账户
            observer.onNext([])
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func deleteAccount(accountId: String) -> Observable<Bool> {
        return Observable.create { observer in
            // TODO: 从持久化存储中删除账户
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}

/// 钱包种子管理服务
class WalletSeedService {
    
    private let vaultService: VaultServiceProtocol
    private let derivationService: DerivationServiceProtocol
    
    init(vaultService: VaultServiceProtocol = VaultService(keychainService: KeychainStorageService(service: "Web3Wallet")),
         derivationService: DerivationServiceProtocol = DerivationService()) {
        self.vaultService = vaultService
        self.derivationService = derivationService
    }
    
    /// 保存钱包种子
    func saveWalletSeed(walletId: String, mnemonic: String, password: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                // 暂时使用模拟实现
                // TODO: 替换为真实的 WalletCore 实现
                let mockSeed = Data(repeating: 0, count: 64) // 模拟种子数据
                
                // 加密种子
                guard let encryptedData = self.vaultService.encryptSeed(mockSeed, password: password) else {
                    observer.onNext(false)
                    observer.onCompleted()
                    return Disposables.create()
                }
                
                // 保存加密的种子
                let success = self.vaultService.storeEncryptedWallet(walletId: walletId, encryptedData: encryptedData)
                observer.onNext(success)
                observer.onCompleted()
            } catch {
                observer.onNext(false)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    /// 获取钱包种子
    func getWalletSeed(walletId: String, password: String) -> Observable<Data?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 获取加密的种子数据
            guard let encryptedData = self.vaultService.getEncryptedWallet(walletId: walletId) else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 解密种子
            let seed = self.vaultService.decryptSeed(encryptedData, password: password)
            observer.onNext(seed)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    /// 派生新账户
    func deriveNewAccount(walletId: String, password: String, accountIndex: Int) -> Observable<Account?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 获取钱包种子
            self.getWalletSeed(walletId: walletId, password: password)
                .subscribe(onNext: { seed in
                    guard let seed = seed else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    // 使用 DerivationService 派生新账户
                    let derivationPath = "m/44'/60'/0'/0/\(accountIndex)"
                    guard let privateKey = self.derivationService.derivePrivateKey(from: seed, path: derivationPath),
                          let address = self.derivationService.deriveAddress(from: privateKey, coinType: 60) else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    let account = Account(
                        walletId: walletId,
                        address: address,
                        derivationPath: derivationPath,
                        index: accountIndex
                    )
                    
                    observer.onNext(account)
                    observer.onCompleted()
                })
                .disposed(by: DisposeBag())
            
            return Disposables.create()
        }
    }
}
