//
//  Transaction.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Transaction status enum
enum TransactionStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case success = "success"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .success: return "Success"
        case .failed: return "Failed"
        }
    }
    
    var isCompleted: Bool {
        return self == .success || self == .failed
    }
}

/// Transaction direction enum
enum TransactionDirection: String, CaseIterable, Codable {
    case inbound = "inbound"  // 接收
    case outbound = "outbound" // 发送
    
    var displayName: String {
        switch self {
        case .inbound: return "Received"
        case .outbound: return "Sent"
        }
    }
    
    var icon: String {
        switch self {
        case .inbound: return "↓"
        case .outbound: return "↑"
        }
    }
}

/// Transaction entity
/// Represents transaction records on blockchain
struct Transaction: Equatable, Codable {
    let hash: String
    let from: String
    let to: String
    let amount: Decimal
    let currency: Currency
    let gasUsed: Decimal?
    let gasPrice: Decimal?
    let status: TransactionStatus
    let direction: TransactionDirection
    let timestamp: Date
    let blockNumber: Int?
    let network: Network
    
    /// Formatted transaction amount
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = currency.decimals
        formatter.groupingSeparator = ","
        
        let prefix = direction == .inbound ? "+" : "-"
        let formattedAmount = formatter.string(from: amount as NSDecimalNumber) ?? "0"
        return "\(prefix)\(formattedAmount) \(currency.symbol)"
    }
    
    /// Formatted time display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Explorer link
    var explorerURL: String {
        return "\(network.explorerBase)/tx/\(hash)"
    }
    
    /// Whether it's a send transaction
    var isOutbound: Bool {
        return direction == .outbound
    }
    
    /// Whether it's a receive transaction
    var isInbound: Bool {
        return direction == .inbound
    }
    
    init(hash: String,
         from: String,
         to: String,
         amount: Decimal,
         currency: Currency,
         gasUsed: Decimal? = nil,
         gasPrice: Decimal? = nil,
         status: TransactionStatus,
         direction: TransactionDirection,
         timestamp: Date,
         blockNumber: Int? = nil,
         network: Network) {
        self.hash = hash
        self.from = from
        self.to = to
        self.amount = amount
        self.currency = currency
        self.gasUsed = gasUsed
        self.gasPrice = gasPrice
        self.status = status
        self.direction = direction
        self.timestamp = timestamp
        self.blockNumber = blockNumber
        self.network = network
    }
}
