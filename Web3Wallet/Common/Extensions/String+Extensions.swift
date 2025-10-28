//
//  String+Extensions.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

extension String {
    
    /// 检查是否为有效的以太坊地址
    var isValidEthereumAddress: Bool {
        return hasPrefix("0x") && count == 42 && dropFirst(2).allSatisfy { $0.isHexDigit }
    }
    
    /// 检查是否为有效的十六进制字符串
    var isValidHex: Bool {
        return allSatisfy { $0.isHexDigit }
    }
    
    /// 移除 0x 前缀
    var removingHexPrefix: String {
        return hasPrefix("0x") ? String(dropFirst(2)) : self
    }
    
    /// 添加 0x 前缀
    var withHexPrefix: String {
        return hasPrefix("0x") ? self : "0x\(self)"
    }
    
    /// 格式化为地址显示（中间省略）
    var formattedAddress: String {
        guard count >= 10 else { return self }
        let prefix = String(prefix(6))
        let suffix = String(suffix(4))
        return "\(prefix)…\(suffix)"
    }
    
    /// 格式化为大数字显示
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
    
    /// 检查是否为空或只包含空白字符
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 移除首尾空白字符
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 转换为 Data
    var data: Data? {
        return data(using: .utf8)
    }
    
    /// 从十六进制字符串转换为 Data
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
    
    /// 本地化字符串
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// 带参数的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
