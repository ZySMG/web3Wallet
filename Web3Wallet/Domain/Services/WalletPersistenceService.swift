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

/// Mock wallet storage service
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

/// Wallet persistence service protocol
protocol WalletPersistenceServiceProtocol {
    /// Save wallet
    func saveWallet(_ wallet: Wallet) -> Observable<Bool>
    
    /// Get all wallets
    func getAllWallets() -> Observable<[Wallet]>
    
    /// Delete wallet
    func deleteWallet(walletId: String) -> Observable<Bool>
    
    /// Update wallet
    func updateWallet(_ wallet: Wallet) -> Observable<Bool>
    
    /// Save account
    func saveAccount(_ account: Account) -> Observable<Bool>
    
    /// Get all accounts of wallet
    func getAccounts(for walletId: String) -> Observable<[Account]>
    
    /// Delete account
    func deleteAccount(accountId: String) -> Observable<Bool>
}

/// Wallet persistence service implementation
class WalletPersistenceService: WalletPersistenceServiceProtocol {
    
    private let walletStore: WalletStoreProtocol
    private let vaultService: VaultServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(walletStore: WalletStoreProtocol? = nil,
         vaultService: VaultServiceProtocol = VaultService(keychainService: KeychainStorageService(service: "Web3Wallet"))) {
        // Temporarily use mock implementation
        // TODO: Implement real WalletStore initialization
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
            
            // Save to WalletStore
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
            
            // Delete from WalletStore
            let success = self.walletStore.deleteWallet(walletId: walletId)
            
            // Delete encrypted data from VaultService
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
            // Account persistence logic can be implemented here
            // Can use UserDefaults, Core Data or SQLite
            // Currently using simple in-memory storage
            
            // TODO: Implement real persistent storage
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func getAccounts(for walletId: String) -> Observable<[Account]> {
        return Observable.create { observer in
            // TODO: Get accounts from persistent storage
            observer.onNext([])
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func deleteAccount(accountId: String) -> Observable<Bool> {
        return Observable.create { observer in
            // TODO: Delete account from persistent storage
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}

/// Wallet seed management service
class WalletSeedService {
    
    private let vaultService: VaultServiceProtocol
    private let derivationService: DerivationServiceProtocol
    
    init(vaultService: VaultServiceProtocol = VaultService(keychainService: KeychainStorageService(service: "Web3Wallet")),
         derivationService: DerivationServiceProtocol = DerivationService()) {
        self.vaultService = vaultService
        self.derivationService = derivationService
    }
    
    /// Save wallet seed
    func saveWalletSeed(walletId: String, mnemonic: String, password: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                // Temporarily use mock implementation
                // TODO: Replace with real WalletCore implementation
                let mockSeed = Data(repeating: 0, count: 64) // 模拟种子数据
                
                // Encrypt seed
                guard let encryptedData = self.vaultService.encryptSeed(mockSeed, password: password) else {
                    observer.onNext(false)
                    observer.onCompleted()
                    return Disposables.create()
                }
                
                // Save encrypted seed
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
    
    /// Get wallet seed
    func getWalletSeed(walletId: String, password: String) -> Observable<Data?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Get encrypted seed data
            guard let encryptedData = self.vaultService.getEncryptedWallet(walletId: walletId) else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Decrypt seed
            let seed = self.vaultService.decryptSeed(encryptedData, password: password)
            observer.onNext(seed)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    /// Derive new account
    func deriveNewAccount(walletId: String, password: String, accountIndex: Int) -> Observable<Account?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Get wallet seed
            self.getWalletSeed(walletId: walletId, password: password)
                .subscribe(onNext: { seed in
                    guard let seed = seed else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    // Use DerivationService to derive new account
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
