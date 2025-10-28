//
//  Decimal+Extensions.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

extension Decimal {
    
    /// 转换为 Double
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
    
    /// 转换为 Float
    var floatValue: Float {
        return NSDecimalNumber(decimal: self).floatValue
    }
    
    /// 转换为 Int
    var intValue: Int {
        return NSDecimalNumber(decimal: self).intValue
    }
    
    /// 转换为 String
    var stringValue: String {
        return NSDecimalNumber(decimal: self).stringValue
    }
    
    /// 格式化为货币显示
    func formatted(decimals: Int = 2, showSymbol: Bool = false, symbol: String = "$") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        formatter.groupingSeparator = ","
        
        let formatted = formatter.string(from: self as NSDecimalNumber) ?? "0"
        
        if showSymbol {
            return "\(symbol)\(formatted)"
        }
        
        return formatted
    }
    
    /// 格式化为百分比
    func formattedAsPercentage(decimals: Int = 2) -> String {
        let percentage = self * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        
        return "\(formatter.string(from: percentage as NSDecimalNumber) ?? "0")%"
    }
    
    /// 检查是否为零
    var isZero: Bool {
        return self == 0
    }
    
    /// 检查是否为正数
    var isPositive: Bool {
        return self > 0
    }
    
    /// 检查是否为负数
    var isNegative: Bool {
        return self < 0
    }
    
    /// 绝对值
    var absoluteValue: Decimal {
        return self < 0 ? -self : self
    }
    
    /// 四舍五入到指定小数位
    func rounded(toPlaces places: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, places, .plain)
        return result
    }
    
    /// 截断到指定小数位
    func truncated(toPlaces places: Int) -> Decimal {
        let divisor = pow(10, places)
        return Decimal(Int((self * divisor).doubleValue)) / divisor
    }
}
