//
//  String+Extensions.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

extension String {
    
    /// Check if it's a valid Ethereum address
    var isValidEthereumAddress: Bool {
        return hasPrefix("0x") && count == 42 && dropFirst(2).allSatisfy { $0.isHexDigit }
    }
    
    /// Check if it's a valid hexadecimal string
    var isValidHex: Bool {
        return allSatisfy { $0.isHexDigit }
    }
    
    /// Remove 0x prefix
    var removingHexPrefix: String {
        return hasPrefix("0x") ? String(dropFirst(2)) : self
    }
    
    /// Add 0x prefix
    var withHexPrefix: String {
        return hasPrefix("0x") ? self : "0x\(self)"
    }
    
    /// Format as address display (middle omitted)
    var formattedAddress: String {
        guard count >= 10 else { return self }
        let prefix = String(prefix(6))
        let suffix = String(suffix(4))
        return "\(prefix)…\(suffix)"
    }
    
    /// Format as large number display
    var formattedLargeNumber: String {
        guard let number = Double(self) else { return self }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        if number >= 1_000_000_000 {
            return "\(formatter.string(from: NSNumber(value: number / 1_000_000_000)) ?? "0")B"
        } else if number >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: number / 1_000_000)) ?? "0")M"
        } else if number >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: number / 1_000)) ?? "0")K"
        } else {
            return formatter.string(from: NSNumber(value: number)) ?? self
        }
    }
    
    /// Check if it's empty or contains only whitespace characters
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Remove leading and trailing whitespace characters
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Convert to Data
    var data: Data? {
        return data(using: .utf8)
    }
    
    /// Convert from hexadecimal string to Data
    var hexData: Data? {
        let hex = removingHexPrefix
        guard hex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = String(hex[index..<nextIndex])
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        return data
    }
    
    /// Localized string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Localized string with arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
