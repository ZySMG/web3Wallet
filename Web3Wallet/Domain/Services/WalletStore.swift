//
//  WalletStore.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// Wallet index structure
struct WalletIndex: Codable, Equatable {
    let wallets: [Wallet]
    var activeWalletId: String?
    let lastUpdated: Date
    var items: [String: Wallet]
    var order: [String]
    
    init(wallets: [Wallet] = [], activeWalletId: String? = nil, lastUpdated: Date = Date()) {
        self.wallets = wallets
        self.activeWalletId = activeWalletId
        self.lastUpdated = lastUpdated
        self.items = Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
        self.order = wallets.map { $0.id }
    }
}

/// Wallet storage service protocol
protocol WalletStoreProtocol {
    /// Get wallet index
    func getWalletIndex() -> WalletIndex
    
    /// Save wallet index
    func saveWalletIndex(_ index: WalletIndex) -> Bool
    
    /// Add new wallet
    func addWallet(_ wallet: Wallet) -> Bool
    
    /// Update wallet
    func updateWallet(_ wallet: Wallet) -> Bool
    
    /// Delete wallet
    func deleteWallet(walletId: String) -> Bool
    
    /// Set active wallet
    func setActiveWallet(walletId: String) -> Bool
    
    /// Get active wallet
    func getActiveWallet() -> Wallet?
    
    /// Get all wallets
    func getAllWallets() -> [Wallet]
    
    /// Check if wallet already exists (by fingerprint)
    func isWalletExists(fingerprint: String) -> (exists: Bool, walletId: String?)
    
    /// Update wallet maximum index
    func updateWalletMaxIndex(walletId: String, maxIndex: Int) -> Bool
    
    /// Wallet index change observer
    var walletIndexSubject: BehaviorRelay<WalletIndex> { get }
}

/// Wallet storage service implementation
class WalletStore: WalletStoreProtocol {
    
    private let keychainService: KeychainStorageServiceProtocol
    private let indexKey = "com.app.wallets.index"
    
    let walletIndexSubject = BehaviorRelay<WalletIndex>(value: WalletIndex())
    
    init(keychainService: KeychainStorageServiceProtocol) {
        self.keychainService = keychainService
        loadWalletIndex()
    }
    
    // MARK: - Public Methods
    
    func getWalletIndex() -> WalletIndex {
        return walletIndexSubject.value
    }
    
    func saveWalletIndex(_ index: WalletIndex) -> Bool {
        do {
            let data = try JSONEncoder().encode(index)
            let success = keychainService.store(key: indexKey, value: data.base64EncodedString())
            
            if success {
                walletIndexSubject.accept(index)
            }
            
            return success
        } catch {
            Logger.error("Failed to encode wallet index: \(error)")
            return false
        }
    }
    
    func addWallet(_ wallet: Wallet) -> Bool {
        var index = walletIndexSubject.value
        
        // Check if already exists
        if let existingWallet = index.wallets.first(where: { $0.id == wallet.id }) {
            Logger.warning("Wallet with id \(wallet.id) already exists")
            return false
        }
        
        // Add to index
        index.items[wallet.id] = wallet
        index.order.append(wallet.id)
        
        // If first wallet, set as active
        if index.activeWalletId == nil {
            index.activeWalletId = wallet.id
        }
        
        return saveWalletIndex(index)
    }
    
    func updateWallet(_ wallet: Wallet) -> Bool {
        var index = walletIndexSubject.value
        
        guard index.items[wallet.id] != nil else {
            Logger.error("Wallet \(wallet.id) not found")
            return false
        }
        
        index.items[wallet.id] = wallet
        return saveWalletIndex(index)
    }
    
    func deleteWallet(walletId: String) -> Bool {
        var index = walletIndexSubject.value
        
        guard index.items[walletId] != nil else {
            Logger.error("Wallet \(walletId) not found")
            return false
        }
        
        // Remove from index
        index.items.removeValue(forKey: walletId)
        index.order.removeAll { $0 == walletId }
        
        // If deleted wallet is active, select new active wallet
        if index.activeWalletId == walletId {
            index.activeWalletId = index.order.first
        }
        
        return saveWalletIndex(index)
    }
    
    func setActiveWallet(walletId: String) -> Bool {
        var index = walletIndexSubject.value
        
        guard index.items[walletId] != nil else {
            Logger.error("Wallet \(walletId) not found")
            return false
        }
        
        index.activeWalletId = walletId
        return saveWalletIndex(index)
    }
    
    func getActiveWallet() -> Wallet? {
        let index = walletIndexSubject.value
        
        guard let activeWalletId = index.activeWalletId else {
            return nil
        }
        
        return index.items[activeWalletId]
    }
    
    func getAllWallets() -> [Wallet] {
        let index = walletIndexSubject.value
        return index.order.compactMap { index.items[$0] }
    }
    
    func isWalletExists(fingerprint: String) -> (exists: Bool, walletId: String?) {
        let index = walletIndexSubject.value
        
        for (walletId, wallet) in index.items {
            if wallet.fingerprint == fingerprint {
                return (true, walletId)
            }
        }
        
        return (false, nil)
    }
    
    func updateWalletMaxIndex(walletId: String, maxIndex: Int) -> Bool {
        var index = walletIndexSubject.value
        
        guard var wallet = index.items[walletId] else {
            Logger.error("Wallet \(walletId) not found")
            return false
        }
        
        // Create updated wallet
        let updatedWallet = Wallet(
            id: wallet.id,
            name: wallet.name,
            address: wallet.address,
            network: wallet.network,
            createdAt: wallet.createdAt,
            isImported: wallet.isImported,
            fingerprint: wallet.fingerprint
        )
        
        index.items[walletId] = updatedWallet
        return saveWalletIndex(index)
    }
    
    // MARK: - Private Methods
    
    private func loadWalletIndex() {
        guard let dataString = keychainService.retrieve(key: indexKey),
              let data = Data(base64Encoded: dataString) else {
            // If no stored index, create default index
            let defaultIndex = WalletIndex()
            walletIndexSubject.accept(defaultIndex)
            return
        }
        
        do {
            let index = try JSONDecoder().decode(WalletIndex.self, from: data)
            walletIndexSubject.accept(index)
        } catch {
            Logger.error("Failed to decode wallet index: \(error)")
            // Create default index
            let defaultIndex = WalletIndex()
            walletIndexSubject.accept(defaultIndex)
        }
    }
}

/// Wallet manager - advanced wallet operations
class WalletManager {
    
    private let walletStore: WalletStoreProtocol
    private let vaultService: VaultServiceProtocol
    private let derivationService: DerivationServiceProtocol
    private let session: WalletSession
    
    init(walletStore: WalletStoreProtocol,
         vaultService: VaultServiceProtocol,
         derivationService: DerivationServiceProtocol,
         session: WalletSession) {
        self.walletStore = walletStore
        self.vaultService = vaultService
        self.derivationService = derivationService
        self.session = session
    }
    
    /// Create new wallet
    func createWallet(label: String, password: String) -> Observable<Wallet> {
        return Observable.create { observer in
            // Generate mnemonic
            guard let mnemonic = self.generateMnemonic() else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // Generate seed
            guard let seed = self.mnemonicToSeed(mnemonic) else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // Generate fingerprint
            let fingerprint = self.vaultService.generateFingerprint(from: seed)
            
            // Check if already exists
            let exists = self.walletStore.isWalletExists(fingerprint: fingerprint)
            if exists.exists {
                observer.onError(WalletError.walletAlreadyExists)
                return Disposables.create()
            }
            
            // Create wallet
            let wallet = Wallet(
                name: label,
                address: fingerprint,
                network: .ethereumMainnet,
                isImported: false,
                fingerprint: fingerprint
            )
            
            // Encrypt and store seed
            guard let encryptedData = self.vaultService.encryptSeed(seed, password: password) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            guard self.vaultService.storeEncryptedWallet(walletId: wallet.id, encryptedData: encryptedData) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            // Save wallet index
            guard self.walletStore.addWallet(wallet) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            observer.onNext(wallet)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// Import wallet
    func importWallet(mnemonic: String, label: String, password: String) -> Observable<Wallet> {
        return Observable.create { observer in
            // Validate mnemonic
            guard self.isValidMnemonic(mnemonic) else {
                observer.onError(WalletError.invalidMnemonic)
                return Disposables.create()
            }
            
            // Generate seed
            guard let seed = self.mnemonicToSeed(mnemonic) else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // Generate fingerprint
            let fingerprint = self.vaultService.generateFingerprint(from: seed)
            
            // Check if already exists
            let exists = self.walletStore.isWalletExists(fingerprint: fingerprint)
            if exists.exists {
                // Switch to existing wallet
                if let walletId = exists.walletId {
                    _ = self.walletStore.setActiveWallet(walletId: walletId)
                    if let wallet = self.walletStore.getActiveWallet() {
                        observer.onNext(wallet)
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }
                observer.onError(WalletError.walletAlreadyExists)
                return Disposables.create()
            }
            
            // Create new wallet
            let wallet = Wallet(
                name: label,
                address: fingerprint,
                network: .ethereumMainnet,
                isImported: true,
                fingerprint: fingerprint
            )
            
            // Encrypt and store seed
            guard let encryptedData = self.vaultService.encryptSeed(seed, password: password) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            guard self.vaultService.storeEncryptedWallet(walletId: wallet.id, encryptedData: encryptedData) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            // Save wallet index
            guard self.walletStore.addWallet(wallet) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            observer.onNext(wallet)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// Unlock wallet
    func unlockWallet(walletId: String, password: String) -> Observable<Bool> {
        return Observable.create { observer in
            // Get encrypted data
            guard let encryptedData = self.vaultService.getEncryptedWallet(walletId: walletId) else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            // Decrypt seed
            guard let seed = self.vaultService.decryptSeed(encryptedData, password: password) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            // Unlock session
            self.session.unlock(walletId: walletId, seed: seed)
            
            // Set as active wallet
            _ = self.walletStore.setActiveWallet(walletId: walletId)
            
            observer.onNext(true)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// Add new account
    func addAccount() -> Observable<Account> {
        return Observable.create { observer in
            guard self.session.isUnlocked else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            guard let wallet = self.walletStore.getActiveWallet() else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            guard let seed = self.session.seed else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            // Calculate new index (simplified implementation)
            let newIndex = 1 // 暂时使用固定索引
            
            // Derive new account
            let derivationRule = DerivationRule.bip44
            let path = "m/44'/60'/0'/0/\(newIndex)"
            
            guard let privateKey = self.derivationService.derivePrivateKey(from: seed, path: path),
                  let address = self.derivationService.deriveAddress(from: privateKey, coinType: derivationRule.coinType) else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // Create new account
            let account = Account(
                walletId: wallet.id,
                address: address,
                derivationPath: path,
                index: newIndex
            )
            
            // Update wallet maximum index
            guard self.walletStore.updateWalletMaxIndex(walletId: wallet.id, maxIndex: newIndex) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            observer.onNext(account)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// Get all accounts of current wallet
    func getCurrentWalletAccounts() -> Observable<[Account]> {
        return Observable.create { observer in
            guard self.session.isUnlocked else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            guard let wallet = self.walletStore.getActiveWallet() else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            guard let seed = self.session.seed else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            // Derive all accounts
            let derivationRule = DerivationRule.bip44
            let accounts = self.derivationService.deriveAccounts(
                from: seed,
                walletId: wallet.id,
                derivationRule: derivationRule,
                maxIndex: 1
            )
            
            observer.onNext(accounts)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// Switch wallet
    func switchWallet(walletId: String, password: String) -> Observable<Bool> {
        return unlockWallet(walletId: walletId, password: password)
    }
    
    /// Lock wallet
    func lockWallet() {
        session.lock()
    }
    
    // MARK: - Private Methods
    
    private func generateMnemonic() -> String? {
        // Temporarily use mock implementation
        // TODO: Replace with real WalletCore implementation
        return "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    }
    
    private func mnemonicToSeed(_ mnemonic: String) -> Data? {
        // Temporarily use mock implementation
        // TODO: Replace with real WalletCore implementation
        return Data(repeating: 0, count: 64) // 模拟种子数据
    }
    
    private func isValidMnemonic(_ mnemonic: String) -> Bool {
        // Temporarily use simple validation
        // TODO: Replace with real WalletCore implementation
        let words = mnemonic.components(separatedBy: .whitespaces)
        return words.count == 12
    }
}

// MARK: - WalletError Extension

extension WalletError {
    static let walletAlreadyExists = WalletError.unknown // TODO: 添加新的错误类型
}
