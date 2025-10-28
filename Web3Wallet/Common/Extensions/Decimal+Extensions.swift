//
//  Decimal+Extensions.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

extension Decimal {
    
    /// Convert to Double
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
    
    /// Convert to Float
    var floatValue: Float {
        return NSDecimalNumber(decimal: self).floatValue
    }
    
    /// Convert to Int
    var intValue: Int {
        return NSDecimalNumber(decimal: self).intValue
    }
    
    /// Convert to String
    var stringValue: String {
        return NSDecimalNumber(decimal: self).stringValue
    }
    
    /// Format as currency display
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
    
    /// Format as percentage
    func formattedAsPercentage(decimals: Int = 2) -> String {
        let percentage = self * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        
        return "\(formatter.string(from: percentage as NSDecimalNumber) ?? "0")%"
    }
    
    /// Check if zero
    var isZero: Bool {
        return self == 0
    }
    
    /// Check if positive
    var isPositive: Bool {
        return self > 0
    }
    
    /// Check if negative
    var isNegative: Bool {
        return self < 0
    }
    
    /// Absolute value
    var absoluteValue: Decimal {
        return self < 0 ? -self : self
    }
    
    /// Round to specified decimal places
    func rounded(toPlaces places: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, places, .plain)
        return result
    }
    
    /// Truncate to specified decimal places
    func truncated(toPlaces places: Int) -> Decimal {
        let divisor = pow(10, places)
        return Decimal(Int((self * divisor).doubleValue)) / divisor
    }
}
