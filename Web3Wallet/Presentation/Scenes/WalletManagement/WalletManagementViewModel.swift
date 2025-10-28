//
//  WalletManagementViewModel.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// Wallet management input
struct WalletManagementInput {
    let walletSelected = PublishRelay<Wallet>()
    let importWalletTrigger = PublishRelay<Void>()
    let addAccountTrigger = PublishRelay<Void>()
    let deleteWalletTrigger = PublishRelay<Wallet>()
    let deleteAccountTrigger = PublishRelay<WalletAccount>()
}

/// Wallet management output
struct WalletManagementOutput {
    let walletSections: Driver<[WalletSection]>
    let showImportWallet: Driver<Void>
    let showAddAccount: Driver<Wallet>
    let walletSwitched: Driver<Wallet>
    let numberOfSections: Driver<Int>
    let numberOfRowsInSection: Driver<[Int: Int]>
    let currentWallet: Driver<Wallet?>
}

/// Wallet management view model
class WalletManagementViewModel {
    
    let input = WalletManagementInput()
    let output: WalletManagementOutput
    
    private let disposeBag = DisposeBag()
    private let keychainStorage: KeychainStorageServiceProtocol
    private let generateMnemonicUseCase: GenerateMnemonicUseCaseProtocol
    private let importWalletUseCase: ImportWalletUseCaseProtocol
    
    // Internal state
    private let walletSectionsSubject = BehaviorRelay<[WalletSection]>(value: [])
    private let showImportWalletSubject = PublishRelay<Void>()
    private let showAddAccountSubject = PublishRelay<Wallet>()
    private let walletSwitchedSubject = PublishRelay<Wallet>()
    private let currentWalletSubject = BehaviorRelay<Wallet?>(value: nil)
    private var accountsStorage: [String: [WalletAccount]] = [:] // 存储每个钱包的账户
    
    init(keychainStorage: KeychainStorageServiceProtocol,
         generateMnemonicUseCase: GenerateMnemonicUseCaseProtocol,
         importWalletUseCase: ImportWalletUseCaseProtocol) {
        
        self.keychainStorage = keychainStorage
        self.generateMnemonicUseCase = generateMnemonicUseCase
        self.importWalletUseCase = importWalletUseCase
        
        self.output = WalletManagementOutput(
            walletSections: walletSectionsSubject.asDriver(),
            showImportWallet: showImportWalletSubject.asDriver(onErrorJustReturn: ()),
            showAddAccount: showAddAccountSubject.asDriver(onErrorJustReturn: Wallet(
                address: "",
                network: .sepolia,
                isImported: false
            )),
            walletSwitched: walletSwitchedSubject.asDriver(onErrorJustReturn: Wallet(
                address: "",
                network: .sepolia,
                isImported: false
            )),
            numberOfSections: walletSectionsSubject.map { $0.count }.asDriver(onErrorJustReturn: 0),
            numberOfRowsInSection: walletSectionsSubject.map { sections in
                var result: [Int: Int] = [:]
                for (index, section) in sections.enumerated() {
                    result[index] = section.accounts.count
                }
                return result
            }.asDriver(onErrorJustReturn: [:]),
            currentWallet: currentWalletSubject.asDriver()
        )
        
        setupBindings()
        setupWalletManagerBindings()
    }
    
    private func setupBindings() {
        // 钱包选择
        input.walletSelected
            .subscribe(onNext: { [weak self] wallet in
                self?.switchToWallet(wallet)
            })
            .disposed(by: disposeBag)
        
        // 导入钱包触发
        input.importWalletTrigger
            .subscribe(onNext: { [weak self] in
                self?.showImportWalletSubject.accept(())
            })
            .disposed(by: disposeBag)
        
        // Add account trigger
        input.addAccountTrigger
            .subscribe(onNext: { [weak self] in
                // Use first wallet as default wallet
                if let firstSection = self?.walletSectionsSubject.value.first {
                    self?.showAddAccountSubject.accept(firstSection.wallet)
                }
            })
            .disposed(by: disposeBag)
        
        // ✅ 监听钱包添加到管理的通知
        NotificationCenter.default.rx
            .notification(.walletAddedToManagement)
            .subscribe(onNext: { [weak self] notification in
                if let wallet = notification.object as? Wallet {
                    self?.addWallet(wallet)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupWalletManagerBindings() {
        // ✅ 监听WalletManagerSingleton的所有钱包变化
        WalletManagerSingleton.shared.allWalletsDriver
            .drive(onNext: { [weak self] wallets in
                self?.updateWalletSections(wallets)
            })
            .disposed(by: disposeBag)
        
        // ✅ 监听WalletManagerSingleton的当前钱包变化
        WalletManagerSingleton.shared.currentWalletDriver
            .drive(onNext: { [weak self] wallet in
                self?.currentWalletSubject.accept(wallet)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateWalletSections(_ wallets: [Wallet]) {
        // ✅ 使用传入的钱包列表，而不是从Keychain重新加载
        let sections = createWalletSections(from: wallets)
        walletSectionsSubject.accept(sections)
    }
    
    private func loadCurrentWallet() {
        // Load current wallet from Keychain - 使用JSON格式解析
        guard let currentWalletString = keychainStorage.retrieve(key: "current_wallet"),
              let walletData = currentWalletString.data(using: .utf8) else {
            return
        }
        
        do {
            let wallet = try JSONDecoder().decode(Wallet.self, from: walletData)
            currentWalletSubject.accept(wallet)
        } catch {
            print("Failed to decode current wallet: \(error)")
            // 如果解析失败，尝试从存储的钱包列表中找到匹配的钱包
            let wallets = loadWalletsFromKeychain()
            if let firstWallet = wallets.first {
                currentWalletSubject.accept(firstWallet)
            }
        }
    }
    
    private func createWalletSections(from wallets: [Wallet]) -> [WalletSection] {
        // ✅ 直接从WalletManagerSingleton获取当前钱包
        let currentWallet = WalletManagerSingleton.shared.currentWalletSubject.value
        
        return wallets.enumerated().map { index, wallet in
            // 获取该钱包的账户，如果没有则创建默认账户
            let accounts = accountsStorage[wallet.address] ?? [createDefaultAccount(for: wallet)]
            
            // ✅ 更新账户的选中状态
            let updatedAccounts = accounts.map { account in
                WalletAccount(
                    id: account.id,
                    name: account.name,
                    address: account.address,
                    walletId: account.walletId,
                    index: account.index,
                    createdAt: account.createdAt,
                    isSelected: currentWallet?.address == wallet.address
                )
            }
            
            // Generate wallet name
            let walletName = wallet.isImported ? "Imported Wallet \(index + 1)" : "Generated Wallet \(index + 1)"
            
            return WalletSection(
                wallet: wallet,
                accounts: updatedAccounts,
                isExpanded: false,
                walletName: walletName,
                isSelected: currentWallet?.address == wallet.address
            )
        }
    }
    
    private func createDefaultAccount(for wallet: Wallet) -> WalletAccount {
        return WalletAccount(
            id: "\(wallet.address)_0",
            name: "Account 1",
            address: wallet.address,
            walletId: wallet.address,
            index: 0,
            createdAt: Date(),
            isSelected: false
        )
    }
    
    private func loadWalletsFromKeychain() -> [Wallet] {
        // Load all stored wallets from Keychain
        if let walletsData = keychainStorage.retrieve(key: "managed_wallets"),
           let wallets = try? JSONDecoder().decode([Wallet].self, from: walletsData.data(using: .utf8) ?? Data()) {
            return wallets
        }
        
        // Return empty array if no wallets stored
        return []
    }
    
    func addWallet(_ wallet: Wallet) {
        // ✅ 使用WalletManagerSingleton添加钱包
        WalletManagerSingleton.shared.addWallet(wallet)
    }
    
    func deleteWallet(_ wallet: Wallet) {
        let wallets = loadWalletsFromKeychain()
        let updatedWallets = wallets.filter { $0.address != wallet.address }
        
        // Save to Keychain
        saveWalletsToKeychain(updatedWallets)
        
        // Update sections
        let sections = createWalletSections(from: updatedWallets)
        walletSectionsSubject.accept(sections)
    }
    
    func addAccount(_ account: WalletAccount) {
        let walletAddress = account.walletId
        
        // 检查账户名称是否重复
        let uniqueName = generateUniqueAccountName(baseName: account.name, walletAddress: walletAddress)
        let uniqueAccount = WalletAccount(
            id: account.id,
            name: uniqueName,
            address: account.address,
            walletId: account.walletId,
            index: account.index,
            createdAt: account.createdAt
        )
        
        // 添加到存储
        if accountsStorage[walletAddress] == nil {
            accountsStorage[walletAddress] = []
        }
        accountsStorage[walletAddress]?.append(uniqueAccount)
        
        // ✅ 更新UserDefaults中的账户计数
        let accountCountKey = "accountCount_\(walletAddress)"
        let currentCount = UserDefaults.standard.integer(forKey: accountCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: accountCountKey)
        
        // ✅ 使用WalletManagerSingleton的钱包列表更新UI
        let wallets = WalletManagerSingleton.shared.allWalletsSubject.value
        let sections = createWalletSections(from: wallets)
        walletSectionsSubject.accept(sections)
    }
    
    private func generateUniqueAccountName(baseName: String, walletAddress: String) -> String {
        let existingAccounts = accountsStorage[walletAddress] ?? []
        let existingNames = Set(existingAccounts.map { $0.name })
        
        if !existingNames.contains(baseName) {
            return baseName
        }
        
        // 如果名称重复，添加数字后缀
        var counter = 2
        var uniqueName = "\(baseName) \(counter)"
        
        while existingNames.contains(uniqueName) {
            counter += 1
            uniqueName = "\(baseName) \(counter)"
        }
        
        return uniqueName
    }
    
    func clearAllWallets() {
        // ✅ 使用WalletManagerSingleton清空所有钱包
        WalletManagerSingleton.shared.clearAllWallets()
        
        // Clear accounts storage
        accountsStorage.removeAll()
    }
    
    func deleteAccount(_ account: WalletAccount) {
        // Find the wallet that contains this account
        let wallets = WalletManagerSingleton.shared.allWalletsSubject.value
        guard let wallet = wallets.first(where: { $0.address == account.walletId }) else {
            print("❌ WalletManagementViewModel: Wallet not found for account \(account.id)")
            return
        }
        
        // Use WalletManagerSingleton to remove the wallet
        WalletManagerSingleton.shared.removeWallet(wallet)
        
        // Clear accounts storage for this wallet
        accountsStorage.removeValue(forKey: wallet.address)
        
        // Update sections from WalletManagerSingleton
        let updatedWallets = WalletManagerSingleton.shared.allWalletsSubject.value
        let sections = createWalletSections(from: updatedWallets)
        walletSectionsSubject.accept(sections)
        
        print("🗑️ WalletManagementViewModel: Deleted account \(account.id) and wallet \(wallet.address)")
    }
    
    private func saveWalletsToKeychain(_ wallets: [Wallet]) {
        // Save all wallets to Keychain
        if let walletsData = try? JSONEncoder().encode(wallets),
           let walletsString = String(data: walletsData, encoding: .utf8) {
            _ = keychainStorage.store(key: "managed_wallets", value: walletsString)
        }
    }
    
    private func switchToWallet(_ wallet: Wallet) {
        // ✅ 使用WalletManagerSingleton设置当前钱包
        WalletManagerSingleton.shared.setCurrentWallet(wallet)
        
        walletSwitchedSubject.accept(wallet)
    }
}

/// Wallet section for grouped display
struct WalletSection {
    let wallet: Wallet
    let accounts: [WalletAccount]
    let isExpanded: Bool
    let walletName: String
    let isSelected: Bool
    
    init(wallet: Wallet, accounts: [WalletAccount], isExpanded: Bool, walletName: String? = nil, isSelected: Bool = false) {
        self.wallet = wallet
        self.accounts = accounts
        self.isExpanded = isExpanded
        self.walletName = walletName ?? (wallet.isImported ? "Imported Wallet" : "Generated Wallet")
        self.isSelected = isSelected
    }
}

/// Wallet account entity
struct WalletAccount {
    let id: String
    let name: String
    let address: String
    let walletId: String
    let index: Int
    let createdAt: Date
    let isSelected: Bool
    
    init(id: String, name: String, address: String, walletId: String, index: Int, createdAt: Date, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.address = address
        self.walletId = walletId
        self.index = index
        self.createdAt = createdAt
        self.isSelected = isSelected
    }
}
