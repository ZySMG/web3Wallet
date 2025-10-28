//
//  Balance.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// 余额实体
/// 表示特定代币的余额信息
struct Balance: Equatable, Codable {
    let currency: Currency
    let amount: Decimal
    let usdValue: Decimal?
    let lastUpdated: Date
    
    /// 格式化的余额显示
    var formattedAmount: String {
        return formatAmount(amount, decimals: currency.decimals)
    }
    
    /// 格式化的 USD 价值显示
    var formattedUSDValue: String {
        guard let usdValue = usdValue else { return "N/A" }
        return String(format: "$%.2f", usdValue.doubleValue)
    }
    
    /// 是否为有效余额（大于0）
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
