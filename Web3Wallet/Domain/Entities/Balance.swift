//
//  Balance.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Balance entity
/// Represents balance information for a specific token
struct Balance: Equatable, Codable {
    let currency: Currency
    let amount: Decimal
    let usdValue: Decimal?
    let lastUpdated: Date
    
    /// Formatted balance display
    var formattedAmount: String {
        return formatAmount(amount, decimals: currency.decimals)
    }
    
    /// Formatted USD value display
    var formattedUSDValue: String {
        guard let usdValue = usdValue else { return "N/A" }
        return String(format: "$%.2f", usdValue.doubleValue)
    }
    
    /// Whether it's a valid balance (greater than 0)
    var isValid: Bool {
        return amount > 0
    }
    
    private func formatAmount(_ amount: Decimal, decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        formatter.groupingSeparator = ","
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
    
    init(currency: Currency, amount: Decimal, usdValue: Decimal? = nil, lastUpdated: Date = Date()) {
        self.currency = currency
        self.amount = amount
        self.usdValue = usdValue
        self.lastUpdated = lastUpdated
    }
}
