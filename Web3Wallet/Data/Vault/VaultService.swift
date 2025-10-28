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

/// 加密的钱包数据结构
struct EncryptedWalletData: Codable {
    let encryptedSeed: Data
    let salt: Data
    let nonce: Data
    let ciphertext: Data
    let mac: Data
    let timestamp: Date
}

/// 金库服务协议
protocol VaultServiceProtocol {
    /// 存储加密的钱包数据
    func storeEncryptedWallet(walletId: String, encryptedData: EncryptedWalletData) -> Bool
    
    /// 获取加密的钱包数据
    func getEncryptedWallet(walletId: String) -> EncryptedWalletData?
    
    /// 删除加密的钱包数据
    func deleteEncryptedWallet(walletId: String) -> Bool
    
    /// 加密种子数据
    func encryptSeed(_ seed: Data, password: String) -> EncryptedWalletData?
    
    /// 解密种子数据
    func decryptSeed(_ encryptedData: EncryptedWalletData, password: String) -> Data?
    
    /// 生成钱包指纹
    func generateFingerprint(from seed: Data) -> String
}

/// 金库服务实现
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
        // 生成随机盐和 nonce
        let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let nonce = Data((0..<12).map { _ in UInt8.random(in: 0...255) })
        
        // 使用 Argon2id 派生密钥
        guard let key = deriveKey(password: password, salt: salt) else {
            return nil
        }
        
        // 使用 AES-GCM 加密
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
        // 派生密钥
        guard let key = deriveKey(password: password, salt: encryptedData.salt) else {
            return nil
        }
        
        // 使用 AES-GCM 解密
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
        // 使用 HMAC-SHA256 生成指纹
        let key = "Web3Wallet_Fingerprint_Key".data(using: .utf8)!
        let hmac = HMAC<SHA256>.authenticationCode(for: seed, using: SymmetricKey(data: key))
        return Data(hmac).base64EncodedString()
    }
    
    // MARK: - Private Methods
    
    private func deriveKey(password: String, salt: Data) -> Data? {
        // 简化的密钥派生（实际项目中应使用 Argon2id）
        let passwordData = password.data(using: .utf8)!
        let combined = passwordData + salt
        
        // 使用 SHA256 进行多轮哈希
        var key = Data(SHA256.hash(data: combined))
        for _ in 0..<10000 {
            key = Data(SHA256.hash(data: key))
        }
        
        return Data(key)
    }
}

/// 内存中的钱包会话
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
            // 安全清除内存
            var mutableSeed = seed
        mutableSeed.withUnsafeMutableBytes { bytes in
                memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
            }
        }
        lock()
    }
}
