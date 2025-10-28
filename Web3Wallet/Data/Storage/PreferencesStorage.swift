//
//  PreferencesStorage.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Preferences storage service protocol
protocol PreferencesStorageServiceProtocol {
    func store<T: Codable>(key: String, value: T)
    func retrieve<T: Codable>(key: String, type: T.Type) -> T?
    func delete(key: String)
    func exists(key: String) -> Bool
}

/// Preferences storage service implementation
class PreferencesStorageService: PreferencesStorageServiceProtocol {
    
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func store<T: Codable>(key: String, value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to store preference for key: \(key), error: \(error)")
        }
    }
    
    func retrieve<T: Codable>(key: String, type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to retrieve preference for key: \(key), error: \(error)")
            return nil
        }
    }
    
    func delete(key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func exists(key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}

/// Storage key constants
struct StorageKeys {
    static let currentWallet = "current_wallet"
    static let selectedNetwork = "selected_network"
    static let biometricsEnabled = "biometrics_enabled"
    static let lastBalanceUpdate = "last_balance_update"
    static let lastPriceUpdate = "last_price_update"
    static let lastTxUpdate = "last_tx_update"
}
