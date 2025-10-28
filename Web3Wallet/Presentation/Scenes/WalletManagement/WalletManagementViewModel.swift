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
        // Wallet selection
        input.walletSelected
            .subscribe(onNext: { [weak self] wallet in
                self?.switchToWallet(wallet)
            })
            .disposed(by: disposeBag)
        
        // Import wallet trigger
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
        
        // ✅ Listen to wallet added to management notification
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
        // ✅ Listen to WalletManagerSingleton all wallets changes
        WalletManagerSingleton.shared.allWalletsDriver
            .drive(onNext: { [weak self] wallets in
                self?.updateWalletSections(wallets)
            })
            .disposed(by: disposeBag)
        
        // ✅ Listen to WalletManagerSingleton current wallet changes
        WalletManagerSingleton.shared.currentWalletDriver
            .drive(onNext: { [weak self] wallet in
                self?.currentWalletSubject.accept(wallet)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateWalletSections(_ wallets: [Wallet]) {
        // ✅ Use passed wallet list instead of reloading from Keychain
        let sections = createWalletSections(from: wallets)
        walletSectionsSubject.accept(sections)
    }
    
    private func loadCurrentWallet() {
        // Load current wallet from Keychain - use JSON format parsing
        guard let currentWalletString = keychainStorage.retrieve(key: "current_wallet"),
              let walletData = currentWalletString.data(using: .utf8) else {
            return
        }
        
        do {
            let wallet = try JSONDecoder().decode(Wallet.self, from: walletData)
            currentWalletSubject.accept(wallet)
        } catch {
            print("Failed to decode current wallet: \(error)")
            // If parsing fails, try to find matching wallet from stored wallet list
            let wallets = loadWalletsFromKeychain()
            if let firstWallet = wallets.first {
                currentWalletSubject.accept(firstWallet)
            }
        }
    }
    
    private func createWalletSections(from wallets: [Wallet]) -> [WalletSection] {
        // ✅ Get current wallet directly from WalletManagerSingleton
        let currentWallet = WalletManagerSingleton.shared.currentWalletSubject.value
        
        return wallets.enumerated().map { index, wallet in
            // Get wallet accounts, create default account if none
            let accounts = accountsStorage[wallet.address] ?? [createDefaultAccount(for: wallet)]
            
            // ✅ Update account selection state
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
        // ✅ Use WalletManagerSingleton to add wallet
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
        
        // Check if account name is duplicate
        let uniqueName = generateUniqueAccountName(baseName: account.name, walletAddress: walletAddress)
        let uniqueAccount = WalletAccount(
            id: account.id,
            name: uniqueName,
            address: account.address,
            walletId: account.walletId,
            index: account.index,
            createdAt: account.createdAt
        )
        
        // Add to storage
        if accountsStorage[walletAddress] == nil {
            accountsStorage[walletAddress] = []
        }
        accountsStorage[walletAddress]?.append(uniqueAccount)
        
        // ✅ Update account count in UserDefaults
        let accountCountKey = "accountCount_\(walletAddress)"
        let currentCount = UserDefaults.standard.integer(forKey: accountCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: accountCountKey)
        
        // ✅ Use WalletManagerSingleton wallet list to update UI
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
        
        // If name is duplicate, add number suffix
        var counter = 2
        var uniqueName = "\(baseName) \(counter)"
        
        while existingNames.contains(uniqueName) {
            counter += 1
            uniqueName = "\(baseName) \(counter)"
        }
        
        return uniqueName
    }
    
    func clearAllWallets() {
        // ✅ Use WalletManagerSingleton to clear all wallets
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
        // ✅ Use WalletManagerSingleton to set current wallet
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
