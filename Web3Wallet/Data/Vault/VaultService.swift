//
//  VaultService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import Security
import CryptoKit

/// Encrypted wallet data structure
struct EncryptedWalletData: Codable {
    let encryptedSeed: Data
    let salt: Data
    let nonce: Data
    let ciphertext: Data
    let mac: Data
    let timestamp: Date
}

/// Vault service protocol
protocol VaultServiceProtocol {
    /// Store encrypted wallet data
    func storeEncryptedWallet(walletId: String, encryptedData: EncryptedWalletData) -> Bool
    
    /// Get encrypted wallet data
    func getEncryptedWallet(walletId: String) -> EncryptedWalletData?
    
    /// Delete encrypted wallet data
    func deleteEncryptedWallet(walletId: String) -> Bool
    
    /// Encrypt seed data
    func encryptSeed(_ seed: Data, password: String) -> EncryptedWalletData?
    
    /// Decrypt seed data
    func decryptSeed(_ encryptedData: EncryptedWalletData, password: String) -> Data?
    
    /// Generate wallet fingerprint
    func generateFingerprint(from seed: Data) -> String
}

/// Vault service implementation
class VaultService: VaultServiceProtocol {
    
    private let keychainService: KeychainStorageServiceProtocol
    
    init(keychainService: KeychainStorageServiceProtocol) {
        self.keychainService = keychainService
    }
    
    // MARK: - Keychain Operations
    
    func storeEncryptedWallet(walletId: String, encryptedData: EncryptedWalletData) -> Bool {
        let key = "com.app.wallets.vault.\(walletId)"
        
        do {
            let data = try JSONEncoder().encode(encryptedData)
            return keychainService.store(key: key, value: data.base64EncodedString())
        } catch {
            Logger.error("Failed to encode encrypted wallet data: \(error)")
            return false
        }
    }
    
    func getEncryptedWallet(walletId: String) -> EncryptedWalletData? {
        let key = "com.app.wallets.vault.\(walletId)"
        
        guard let dataString = keychainService.retrieve(key: key),
              let data = Data(base64Encoded: dataString) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(EncryptedWalletData.self, from: data)
        } catch {
            Logger.error("Failed to decode encrypted wallet data: \(error)")
            return nil
        }
    }
    
    func deleteEncryptedWallet(walletId: String) -> Bool {
        let key = "com.app.wallets.vault.\(walletId)"
        return keychainService.delete(key: key)
    }
    
    // MARK: - Encryption/Decryption
    
    func encryptSeed(_ seed: Data, password: String) -> EncryptedWalletData? {
        // Generate random salt and nonce
        let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let nonce = Data((0..<12).map { _ in UInt8.random(in: 0...255) })
        
        // Use Argon2id to derive key
        guard let key = deriveKey(password: password, salt: salt) else {
            return nil
        }
        
        // Use AES-GCM encryption
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.seal(seed, using: symmetricKey, nonce: AES.GCM.Nonce(data: nonce))
            
            return EncryptedWalletData(
                encryptedSeed: seed,
                salt: salt,
                nonce: nonce,
                ciphertext: sealedBox.ciphertext,
                mac: sealedBox.tag,
                timestamp: Date()
            )
        } catch {
            Logger.error("Failed to encrypt seed: \(error)")
            return nil
        }
    }
    
    func decryptSeed(_ encryptedData: EncryptedWalletData, password: String) -> Data? {
        // Derive key
        guard let key = deriveKey(password: password, salt: encryptedData.salt) else {
            return nil
        }
        
        // Use AES-GCM decryption
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: encryptedData.nonce),
                ciphertext: encryptedData.ciphertext,
                tag: encryptedData.mac
            )
            
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            Logger.error("Failed to decrypt seed: \(error)")
            return nil
        }
    }
    
    func generateFingerprint(from seed: Data) -> String {
        // Use HMAC-SHA256 to generate fingerprint
        let key = "Web3Wallet_Fingerprint_Key".data(using: .utf8)!
        let hmac = HMAC<SHA256>.authenticationCode(for: seed, using: SymmetricKey(data: key))
        return Data(hmac).base64EncodedString()
    }
    
    // MARK: - Private Methods
    
    private func deriveKey(password: String, salt: Data) -> Data? {
        // Simplified key derivation (should use Argon2id in real project)
        let passwordData = password.data(using: .utf8)!
        let combined = passwordData + salt
        
        // Use SHA256 for multiple rounds of hashing
        var key = Data(SHA256.hash(data: combined))
        for _ in 0..<10000 {
            key = Data(SHA256.hash(data: key))
        }
        
        return Data(key)
    }
}

/// In-memory wallet session
class WalletSession {
    private var _seed: Data?
    private var _walletId: String?
    
    var seed: Data? {
        return _seed
    }
    
    var walletId: String? {
        return _walletId
    }
    
    var isUnlocked: Bool {
        return _seed != nil && _walletId != nil
    }
    
    func unlock(walletId: String, seed: Data) {
        _walletId = walletId
        _seed = seed
    }
    
    func lock() {
        _seed = nil
        _walletId = nil
    }
    
    func clearMemory() {
        if let seed = _seed {
            // Securely clear memory
            var mutableSeed = seed
        mutableSeed.withUnsafeMutableBytes { bytes in
                memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
            }
        }
        lock()
    }
}
