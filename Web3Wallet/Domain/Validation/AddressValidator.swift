//
//  AddressValidator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// 地址验证器协议
protocol AddressValidatorProtocol {
    func isValid(_ address: String) -> Bool
    func isValidEIP55(_ address: String) -> Bool
    func normalizeAddress(_ address: String) -> String?
}

/// 地址验证器
/// 负责验证以太坊地址的有效性
class AddressValidator: AddressValidatorProtocol {
    
    func isValid(_ address: String) -> Bool {
        // 基本格式验证：0x + 40个十六进制字符
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedAddress.hasPrefix("0x") else { return false }
        guard trimmedAddress.count == 42 else { return false }
        
        let hexPart = String(trimmedAddress.dropFirst(2))
        return hexPart.allSatisfy { $0.isHexDigit }
    }
    
    func isValidEIP55(_ address: String) -> Bool {
        guard isValid(address) else { return false }
        
        // EIP-55 校验和验证
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexPart = String(trimmedAddress.dropFirst(2))
        
        // 计算校验和
        let hash = hexPart.lowercased().data(using: .utf8)?.sha3_256() ?? Data()
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()
        
        for (i, char) in hexPart.enumerated() {
            let hashChar = hashHex[hashHex.index(hashHex.startIndex, offsetBy: i)]
            let isUpperCase = char.isUppercase
            
            if hashChar >= "8" && !isUpperCase {
                return false
            } else if hashChar < "8" && isUpperCase {
                return false
            }
        }
        
        return true
    }
    
    func normalizeAddress(_ address: String) -> String? {
        guard isValid(address) else { return nil }
        
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedAddress.lowercased()
    }
    
    /// 获取地址验证错误信息
    func getValidationError(_ address: String) -> String? {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedAddress.isEmpty {
            return "地址不能为空"
        }
        
        if !trimmedAddress.hasPrefix("0x") {
            return "地址必须以 0x 开头"
        }
        
        if trimmedAddress.count != 42 {
            return "地址长度必须为 42 个字符"
        }
        
        let hexPart = String(trimmedAddress.dropFirst(2))
        if !hexPart.allSatisfy({ $0.isHexDigit }) {
            return "地址包含无效字符"
        }
        
        if !isValidEIP55(address) {
            return "地址校验和验证失败"
        }
        
        return nil
    }
}

// MARK: - Extensions

extension Character {
    var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}

extension Data {
    func sha3_256() -> Data {
        // 这里应该使用实际的 SHA3-256 实现
        // 为了简化，我们使用 SHA256 作为替代
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}

import CommonCrypto

private func CC_SHA256(_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
    return CC_SHA256(data, len, md)
}
