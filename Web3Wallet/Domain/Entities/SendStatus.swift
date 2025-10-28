//
//  SendStatus.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Send status enum
enum SendStatus {
    case sending          // 发送中
    case success(txHash: String)  // 发送成功，包含交易哈希
    case failed(error: Error)    // 发送失败，包含错误信息
    
    var displayText: String {
        switch self {
        case .sending:
            return "Sending Transaction..."
        case .success:
            return "Transaction Sent Successfully!"
        case .failed:
            return "Transaction Failed"
        }
    }
    
    var isCompleted: Bool {
        switch self {
        case .sending:
            return false
        case .success, .failed:
            return true
        }
    }
    
    var canViewTransaction: Bool {
        switch self {
        case .success:
            return true
        case .sending, .failed:
            return false
        }
    }
    
    var transactionHash: String? {
        switch self {
        case .success(let txHash):
            return txHash
        case .sending, .failed:
            return nil
        }
    }
}
