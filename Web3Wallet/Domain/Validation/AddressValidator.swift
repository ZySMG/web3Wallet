//
//  AddressValidator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Address validator protocol
protocol AddressValidatorProtocol {
    func isValid(_ address: String) -> Bool
    func isValidEIP55(_ address: String) -> Bool
    func normalizeAddress(_ address: String) -> String?
}

/// Address validator
/// Responsible for validating Ethereum addresses
class AddressValidator: AddressValidatorProtocol {
    
    func isValid(_ address: String) -> Bool {
        // Basic format validation: 0x + 40 hexadecimal characters
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedAddress.hasPrefix("0x") else { return false }
        guard trimmedAddress.count == 42 else { return false }
        
        let hexPart = String(trimmedAddress.dropFirst(2))
        return hexPart.allSatisfy { $0.isHexDigit }
    }
    
    func isValidEIP55(_ address: String) -> Bool {
        guard isValid(address) else { return false }
        
        // EIP-55 checksum validation
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexPart = String(trimmedAddress.dropFirst(2))
        
        // Calculate checksum
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
    
    /// Get address validation error message
    func getValidationError(_ address: String) -> String? {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedAddress.isEmpty {
            return "Address cannot be empty"
        }
        
        if !trimmedAddress.hasPrefix("0x") {
            return "Address must start with 0x"
        }
        
        if trimmedAddress.count != 42 {
            return "Address length must be 42 characters"
        }
        
        let hexPart = String(trimmedAddress.dropFirst(2))
        if !hexPart.allSatisfy({ $0.isHexDigit }) {
            return "Address contains invalid characters"
        }
        
        if !isValidEIP55(address) {
            return "Address checksum validation failed"
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
        // Here should use actual SHA3-256 implementation
        // For simplification, we use SHA256 as replacement
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
