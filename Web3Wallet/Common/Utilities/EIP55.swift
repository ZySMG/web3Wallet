//
//  EIP55.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import CryptoKit

/// EIP-55 校验和工具类
/// 实现以太坊地址的校验和验证
class EIP55 {
    
    /// 验证地址是否符合 EIP-55 标准
    static func isValid(_ address: String) -> Bool {
        guard address.hasPrefix("0x") && address.count == 42 else { return false }
        
        let hexPart = String(address.dropFirst(2))
        guard hexPart.allSatisfy({ $0.isHexDigit }) else { return false }
        
        // 计算校验和
        let hash = SHA256.hash(data: hexPart.lowercased().data(using: .utf8) ?? Data())
        let hashHex = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // 验证每个字符的大小写
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
    
    /// 将地址转换为 EIP-55 格式
    static func toChecksumAddress(_ address: String) -> String {
        guard address.hasPrefix("0x") && address.count == 42 else { return address }
        
        let hexPart = String(address.dropFirst(2))
        guard hexPart.allSatisfy({ $0.isHexDigit }) else { return address }
        
        // 计算校验和
        let hash = SHA256.hash(data: hexPart.lowercased().data(using: .utf8) ?? Data())
        let hashHex = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        var result = "0x"
        
        for (i, char) in hexPart.lowercased().enumerated() {
            let hashChar = hashHex[hashHex.index(hashHex.startIndex, offsetBy: i)]
            
            if hashChar >= "8" {
                result += String(char).uppercased()
            } else {
                result += String(char)
            }
        }
        
        return result
    }
    
    /// 验证地址格式是否正确（不验证校验和）
    static func isValidFormat(_ address: String) -> Bool {
        return address.hasPrefix("0x") && 
               address.count == 42 && 
               String(address.dropFirst(2)).allSatisfy { $0.isHexDigit }
    }
    
    /// 标准化地址（转换为小写）
    static func normalize(_ address: String) -> String? {
        guard isValidFormat(address) else { return nil }
        return address.lowercased()
    }
    
    /// 获取地址验证错误信息
    static func getValidationError(_ address: String) -> String? {
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
        
        if !isValid(trimmedAddress) {
            return "地址校验和验证失败"
        }
        
        return nil
    }
}

/// 地址格式化工具
class AddressFormatter {
    
    /// 格式化为显示地址（中间省略）
    static func displayAddress(_ address: String, prefixLength: Int = 6, suffixLength: Int = 4) -> String {
        guard address.count >= prefixLength + suffixLength else { return address }
        
        let prefix = String(address.prefix(prefixLength))
        let suffix = String(address.suffix(suffixLength))
        
        return "\(prefix)…\(suffix)"
    }
    
    /// 格式化为完整地址（每4位添加空格）
    static func fullAddress(_ address: String) -> String {
        guard address.hasPrefix("0x") else { return address }
        
        let hexPart = String(address.dropFirst(2))
        var formatted = "0x"
        
        for (index, char) in hexPart.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        
        return formatted
    }
    
    /// 格式化为二维码地址（移除空格）
    static func qrCodeAddress(_ address: String) -> String {
        return address.replacingOccurrences(of: " ", with: "")
    }
}

/// 地址验证器扩展
extension String {
    
    /// 检查是否为有效的以太坊地址格式
    var isValidEthereumAddressFormat: Bool {
        return EIP55.isValidFormat(self)
    }
    
    /// 检查是否为有效的 EIP-55 地址
    var isValidEIP55Address: Bool {
        return EIP55.isValid(self)
    }
    
    /// 转换为 EIP-55 格式
    var toChecksumAddress: String {
        return EIP55.toChecksumAddress(self)
    }
    
    /// 标准化地址
    var normalizedAddress: String? {
        return EIP55.normalize(self)
    }
    
    /// 格式化为显示地址
    var displayAddress: String {
        return AddressFormatter.displayAddress(self)
    }
    
    /// 格式化为完整地址
    var fullAddress: String {
        return AddressFormatter.fullAddress(self)
    }
    
    /// 格式化为二维码地址
    var qrCodeAddress: String {
        return AddressFormatter.qrCodeAddress(self)
    }
}
