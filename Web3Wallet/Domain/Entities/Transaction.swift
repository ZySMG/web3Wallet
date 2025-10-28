//
//  Transaction.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// 交易状态枚举
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

/// 交易方向枚举
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

/// 交易实体
/// 表示区块链上的交易记录
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
    
    /// 格式化的交易金额
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
    
    /// 格式化的时间显示
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Explorer 链接
    var explorerURL: String {
        return "\(network.explorerBase)/tx/\(hash)"
    }
    
    /// 是否为发送交易
    var isOutbound: Bool {
        return direction == .outbound
    }
    
    /// 是否为接收交易
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
