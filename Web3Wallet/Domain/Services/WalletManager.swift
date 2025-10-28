//
//  WalletManager.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// Wallet Manager Singleton
/// Responsible for managing the current active wallet and all wallet lists
class WalletManagerSingleton {
    
    static let shared = WalletManagerSingleton()
    
    private let keychainStorage = KeychainStorageService()
    private let disposeBag = DisposeBag()
    
    // MARK: - Current Wallet Management
    
    /// Current active wallet
    let currentWalletSubject = BehaviorRelay<Wallet?>(value: nil)
    var currentWallet: Observable<Wallet?> {
        return currentWalletSubject.asObservable()
    }
    
    /// Driver version of current active wallet
    var currentWalletDriver: Driver<Wallet?> {
        return currentWalletSubject.asDriver()
    }
    
    // MARK: - All Wallets Management
    
    /// All wallets list
    let allWalletsSubject = BehaviorRelay<[Wallet]>(value: [])
    var allWallets: Observable<[Wallet]> {
        return allWalletsSubject.asObservable()
    }
    
    /// Driver version of all wallets list
    var allWalletsDriver: Driver<[Wallet]> {
        return allWalletsSubject.asDriver()
    }
    
    // MARK: - Initialization
    
    private init() {
        loadWalletsFromKeychain()
        loadCurrentWalletFromKeychain()
    }
    
    // MARK: - Public Methods
    
    /// Set current active wallet
    func setCurrentWallet(_ wallet: Wallet) {
        // Update current wallet in memory
        currentWalletSubject.accept(wallet)
        
        // Save to Keychain
        saveCurrentWalletToKeychain(wallet)
        
        // Send wallet switch notification
        NotificationCenter.default.post(name: .walletSwitched, object: wallet)
        
        print("🔄 WalletManagerSingleton: Set current wallet to \(wallet.address)")
    }
    
    /// Add new wallet
    func addWallet(_ wallet: Wallet) {
        var wallets = allWalletsSubject.value
        
        // Check if wallet already exists (by address)
        if wallets.contains(where: { $0.address.lowercased() == wallet.address.lowercased() }) {
            print("⚠️ WalletManagerSingleton: Wallet with address \(wallet.address) already exists")
            return
        }
        
        wallets.append(wallet)
        allWalletsSubject.accept(wallets)
        
        // Save to Keychain
        saveWalletsToKeychain(wallets)
        
        // If this is the first wallet, automatically set as current wallet
        if wallets.count == 1 {
            setCurrentWallet(wallet)
        }
        
        print("✅ WalletManagerSingleton: Added wallet \(wallet.address)")
    }
    
    /// Remove wallet
    func removeWallet(_ wallet: Wallet) {
        var wallets = allWalletsSubject.value
        wallets.removeAll { $0.address.lowercased() == wallet.address.lowercased() }
        allWalletsSubject.accept(wallets)
        
        // Save to Keychain
        saveWalletsToKeychain(wallets)
        
        // If the removed wallet is the current wallet, select a new current wallet
        if currentWalletSubject.value?.address.lowercased() == wallet.address.lowercased() {
            if let newCurrentWallet = wallets.first {
                setCurrentWallet(newCurrentWallet)
            } else {
                // No wallets left, clear current wallet
                currentWalletSubject.accept(nil)
                keychainStorage.delete(key: "current_wallet")
            }
        }
        
        print("🗑️ WalletManagerSingleton: Removed wallet \(wallet.address)")
    }
    
    /// Clear all wallets
    func clearAllWallets() {
        allWalletsSubject.accept([])
        currentWalletSubject.accept(nil)
        
        // Clear Keychain
        keychainStorage.delete(key: "managed_wallets")
        keychainStorage.delete(key: "current_wallet")
        
        print("🧹 WalletManagerSingleton: Cleared all wallets")
    }
    
    /// Check if there are wallets
    func hasWallets() -> Bool {
        return !allWalletsSubject.value.isEmpty
    }
    
    /// Get wallet count
    func walletCount() -> Int {
        return allWalletsSubject.value.count
    }
    
    // MARK: - Private Methods
    
    /// Load all wallets from Keychain
    private func loadWalletsFromKeychain() {
        guard let walletsString = keychainStorage.retrieve(key: "managed_wallets"),
              let walletsData = walletsString.data(using: .utf8) else {
            print("📱 WalletManagerSingleton: No wallets found in Keychain")
            return
        }
        
        do {
            let wallets = try JSONDecoder().decode([Wallet].self, from: walletsData)
            allWalletsSubject.accept(wallets)
            print("📱 WalletManagerSingleton: Loaded \(wallets.count) wallets from Keychain")
        } catch {
            print("❌ WalletManagerSingleton: Failed to decode wallets from Keychain: \(error)")
        }
    }
    
    /// Load current wallet from Keychain
    private func loadCurrentWalletFromKeychain() {
        guard let walletString = keychainStorage.retrieve(key: "current_wallet"),
              let walletData = walletString.data(using: .utf8) else {
            print("📱 WalletManagerSingleton: No current wallet found in Keychain")
            return
        }
        
        do {
            let wallet = try JSONDecoder().decode(Wallet.self, from: walletData)
            currentWalletSubject.accept(wallet)
            print("📱 WalletManagerSingleton: Loaded current wallet \(wallet.address) from Keychain")
        } catch {
            print("❌ WalletManagerSingleton: Failed to decode current wallet from Keychain: \(error)")
        }
    }
    
    /// Save current wallet to Keychain
    private func saveCurrentWalletToKeychain(_ wallet: Wallet) {
        do {
            let walletData = try JSONEncoder().encode(wallet)
            let walletString = String(data: walletData, encoding: .utf8) ?? ""
            keychainStorage.store(key: "current_wallet", value: walletString)
        } catch {
            print("❌ WalletManagerSingleton: Failed to save current wallet to Keychain: \(error)")
        }
    }
    
    /// Save all wallets to Keychain
    private func saveWalletsToKeychain(_ wallets: [Wallet]) {
        do {
            let walletsData = try JSONEncoder().encode(wallets)
            let walletsString = String(data: walletsData, encoding: .utf8) ?? ""
            keychainStorage.store(key: "managed_wallets", value: walletsString)
        } catch {
            print("❌ WalletManagerSingleton: Failed to save wallets to Keychain: \(error)")
        }
    }
}

