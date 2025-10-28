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

/// 钱包索引结构
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

/// 钱包存储服务协议
protocol WalletStoreProtocol {
    /// 获取钱包索引
    func getWalletIndex() -> WalletIndex
    
    /// 保存钱包索引
    func saveWalletIndex(_ index: WalletIndex) -> Bool
    
    /// 添加新钱包
    func addWallet(_ wallet: Wallet) -> Bool
    
    /// 更新钱包
    func updateWallet(_ wallet: Wallet) -> Bool
    
    /// 删除钱包
    func deleteWallet(walletId: String) -> Bool
    
    /// 设置活跃钱包
    func setActiveWallet(walletId: String) -> Bool
    
    /// 获取活跃钱包
    func getActiveWallet() -> Wallet?
    
    /// 获取所有钱包
    func getAllWallets() -> [Wallet]
    
    /// 检查钱包是否已存在（通过指纹）
    func isWalletExists(fingerprint: String) -> (exists: Bool, walletId: String?)
    
    /// 更新钱包的最大索引
    func updateWalletMaxIndex(walletId: String, maxIndex: Int) -> Bool
    
    /// 钱包索引变化观察者
    var walletIndexSubject: BehaviorRelay<WalletIndex> { get }
}

/// 钱包存储服务实现
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
        
        // 检查是否已存在
        if let existingWallet = index.wallets.first(where: { $0.id == wallet.id }) {
            Logger.warning("Wallet with id \(wallet.id) already exists")
            return false
        }
        
        // 添加到索引
        index.items[wallet.id] = wallet
        index.order.append(wallet.id)
        
        // 如果是第一个钱包，设为活跃
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
        
        // 从索引中删除
        index.items.removeValue(forKey: walletId)
        index.order.removeAll { $0 == walletId }
        
        // 如果删除的是活跃钱包，选择新的活跃钱包
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
        
        // 创建更新后的钱包
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
            // 如果没有存储的索引，创建默认索引
            let defaultIndex = WalletIndex()
            walletIndexSubject.accept(defaultIndex)
            return
        }
        
        do {
            let index = try JSONDecoder().decode(WalletIndex.self, from: data)
            walletIndexSubject.accept(index)
        } catch {
            Logger.error("Failed to decode wallet index: \(error)")
            // 创建默认索引
            let defaultIndex = WalletIndex()
            walletIndexSubject.accept(defaultIndex)
        }
    }
}

/// 钱包管理器 - 高级钱包操作
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
    
    /// 创建新钱包
    func createWallet(label: String, password: String) -> Observable<Wallet> {
        return Observable.create { observer in
            // 生成助记词
            guard let mnemonic = self.generateMnemonic() else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // 生成种子
            guard let seed = self.mnemonicToSeed(mnemonic) else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // 生成指纹
            let fingerprint = self.vaultService.generateFingerprint(from: seed)
            
            // 检查是否已存在
            let exists = self.walletStore.isWalletExists(fingerprint: fingerprint)
            if exists.exists {
                observer.onError(WalletError.walletAlreadyExists)
                return Disposables.create()
            }
            
            // 创建钱包
            let wallet = Wallet(
                name: label,
                address: fingerprint,
                network: .ethereumMainnet,
                isImported: false,
                fingerprint: fingerprint
            )
            
            // 加密并存储种子
            guard let encryptedData = self.vaultService.encryptSeed(seed, password: password) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            guard self.vaultService.storeEncryptedWallet(walletId: wallet.id, encryptedData: encryptedData) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            // 保存钱包索引
            guard self.walletStore.addWallet(wallet) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            observer.onNext(wallet)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// 导入钱包
    func importWallet(mnemonic: String, label: String, password: String) -> Observable<Wallet> {
        return Observable.create { observer in
            // 验证助记词
            guard self.isValidMnemonic(mnemonic) else {
                observer.onError(WalletError.invalidMnemonic)
                return Disposables.create()
            }
            
            // 生成种子
            guard let seed = self.mnemonicToSeed(mnemonic) else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // 生成指纹
            let fingerprint = self.vaultService.generateFingerprint(from: seed)
            
            // 检查是否已存在
            let exists = self.walletStore.isWalletExists(fingerprint: fingerprint)
            if exists.exists {
                // 切换到已存在的钱包
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
            
            // 创建新钱包
            let wallet = Wallet(
                name: label,
                address: fingerprint,
                network: .ethereumMainnet,
                isImported: true,
                fingerprint: fingerprint
            )
            
            // 加密并存储种子
            guard let encryptedData = self.vaultService.encryptSeed(seed, password: password) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            guard self.vaultService.storeEncryptedWallet(walletId: wallet.id, encryptedData: encryptedData) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            // 保存钱包索引
            guard self.walletStore.addWallet(wallet) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            observer.onNext(wallet)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// 解锁钱包
    func unlockWallet(walletId: String, password: String) -> Observable<Bool> {
        return Observable.create { observer in
            // 获取加密数据
            guard let encryptedData = self.vaultService.getEncryptedWallet(walletId: walletId) else {
                observer.onError(WalletError.walletNotFound)
                return Disposables.create()
            }
            
            // 解密种子
            guard let seed = self.vaultService.decryptSeed(encryptedData, password: password) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            // 解锁会话
            self.session.unlock(walletId: walletId, seed: seed)
            
            // 设置为活跃钱包
            _ = self.walletStore.setActiveWallet(walletId: walletId)
            
            observer.onNext(true)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// 添加新账户
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
            
            // 计算新索引（简化实现）
            let newIndex = 1 // 暂时使用固定索引
            
            // 派生新账户
            let derivationRule = DerivationRule.bip44
            let path = "m/44'/60'/0'/0/\(newIndex)"
            
            guard let privateKey = self.derivationService.derivePrivateKey(from: seed, path: path),
                  let address = self.derivationService.deriveAddress(from: privateKey, coinType: derivationRule.coinType) else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }
            
            // 创建新账户
            let account = Account(
                walletId: wallet.id,
                address: address,
                derivationPath: path,
                index: newIndex
            )
            
            // 更新钱包的最大索引
            guard self.walletStore.updateWalletMaxIndex(walletId: wallet.id, maxIndex: newIndex) else {
                observer.onError(WalletError.keychainError)
                return Disposables.create()
            }
            
            observer.onNext(account)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    /// 获取当前钱包的所有账户
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
            
            // 派生所有账户
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
    
    /// 切换钱包
    func switchWallet(walletId: String, password: String) -> Observable<Bool> {
        return unlockWallet(walletId: walletId, password: password)
    }
    
    /// 锁定钱包
    func lockWallet() {
        session.lock()
    }
    
    // MARK: - Private Methods
    
    private func generateMnemonic() -> String? {
        // 暂时使用模拟实现
        // TODO: 替换为真实的 WalletCore 实现
        return "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    }
    
    private func mnemonicToSeed(_ mnemonic: String) -> Data? {
        // 暂时使用模拟实现
        // TODO: 替换为真实的 WalletCore 实现
        return Data(repeating: 0, count: 64) // 模拟种子数据
    }
    
    private func isValidMnemonic(_ mnemonic: String) -> Bool {
        // 暂时使用简单的验证
        // TODO: 替换为真实的 WalletCore 实现
        let words = mnemonic.components(separatedBy: .whitespaces)
        return words.count == 12
    }
}

// MARK: - WalletError Extension

extension WalletError {
    static let walletAlreadyExists = WalletError.unknown // TODO: 添加新的错误类型
}
