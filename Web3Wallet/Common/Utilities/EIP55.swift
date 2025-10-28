//
//  EIP55.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import CryptoKit

/// EIP-55 checksum utility class
/// Implements Ethereum address checksum validation
class EIP55 {
    
    /// Verify if address conforms to EIP-55 standard
    static func isValid(_ address: String) -> Bool {
        guard address.hasPrefix("0x") && address.count == 42 else { return false }
        
        let hexPart = String(address.dropFirst(2))
        guard hexPart.allSatisfy({ $0.isHexDigit }) else { return false }
        
        // Calculate checksum
        let hash = SHA256.hash(data: hexPart.lowercased().data(using: .utf8) ?? Data())
        let hashHex = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Verify case of each character
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
    
    /// Convert address to EIP-55 format
    static func toChecksumAddress(_ address: String) -> String {
        guard address.hasPrefix("0x") && address.count == 42 else { return address }
        
        let hexPart = String(address.dropFirst(2))
        guard hexPart.allSatisfy({ $0.isHexDigit }) else { return address }
        
        // Calculate checksum
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
    
    /// Verify if address format is correct (without checksum validation)
    static func isValidFormat(_ address: String) -> Bool {
        return address.hasPrefix("0x") && 
               address.count == 42 && 
               String(address.dropFirst(2)).allSatisfy { $0.isHexDigit }
    }
    
    /// Normalize address (convert to lowercase)
    static func normalize(_ address: String) -> String? {
        guard isValidFormat(address) else { return nil }
        return address.lowercased()
    }
    
    /// Get address validation error message
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

/// Address formatting utility
class AddressFormatter {
    
    /// Format as display address (middle omitted)
    static func displayAddress(_ address: String, prefixLength: Int = 6, suffixLength: Int = 4) -> String {
        guard address.count >= prefixLength + suffixLength else { return address }
        
        let prefix = String(address.prefix(prefixLength))
        let suffix = String(address.suffix(suffixLength))
        
        return "\(prefix)…\(suffix)"
    }
    
    /// Format as full address (add space every 4 characters)
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
    
    /// Format as QR code address (remove spaces)
    static func qrCodeAddress(_ address: String) -> String {
        return address.replacingOccurrences(of: " ", with: "")
    }
}

/// Address validator extension
extension String {
    
    /// Check if it's a valid Ethereum address format
    var isValidEthereumAddressFormat: Bool {
        return EIP55.isValidFormat(self)
    }
    
    /// Check if it's a valid EIP-55 address
    var isValidEIP55Address: Bool {
        return EIP55.isValid(self)
    }
    
    /// Convert to EIP-55 format
    var toChecksumAddress: String {
        return EIP55.toChecksumAddress(self)
    }
    
    /// Normalize address
    var normalizedAddress: String? {
        return EIP55.normalize(self)
    }
    
    /// Format as display address
    var displayAddress: String {
        return AddressFormatter.displayAddress(self)
    }
    
    /// Format as full address
    var fullAddress: String {
        return AddressFormatter.fullAddress(self)
    }
    
    /// Format as QR code address
    var qrCodeAddress: String {
        return AddressFormatter.qrCodeAddress(self)
    }
}
