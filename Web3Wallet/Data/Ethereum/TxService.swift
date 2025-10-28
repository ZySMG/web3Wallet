//
//  TxService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// Transaction service protocol
protocol TxServiceProtocol {
    func getTransactionHistory(address: String, network: Network, limit: Int) -> Observable<[Transaction]>
    func getTransactionDetails(hash: String, network: Network) -> Observable<Transaction>
}

/// Etherscan transaction response
struct EtherscanTxResponse: Codable {
    let status: String
    let message: String
    let result: [EtherscanTransaction]
}

/// Etherscan transaction data
struct EtherscanTransaction: Codable {
    let blockNumber: String
    let timeStamp: String
    let hash: String
    let from: String
    let to: String
    let value: String
    let gas: String
    let gasPrice: String
    let gasUsed: String
    let isError: String
    let txreceipt_status: String
}

/// Transaction service implementation
class TxService: TxServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    private let etherscanV2Service: EtherscanV2Service
    
    init(networkService: NetworkServiceProtocol? = nil) {
        // ✅ Use Sepolia Etherscan API
        self.networkService = networkService ?? NetworkService(baseURL: "https://api-sepolia.etherscan.io/api")
        
        // ✅ Initialize Etherscan V2 service
        self.etherscanV2Service = EtherscanV2Service(
            apiKey: APIKeys.etherscanSepoliaKey,
            chainId: "11155111", // Sepolia chain ID
            baseURL: "https://api.etherscan.io/v2/api"
        )
    }
    
    func getTransactionHistory(address: String, network: Network, limit: Int) -> Observable<[Transaction]> {
        // Check if API Key is available
        guard APIKeys.hasEtherscanKey else {
            // Return empty array if no API key
            return Observable.just([])
        }
        
        // ✅ Use Etherscan V2 API
        return etherscanV2Service.getTransactionHistory(address: address, limit: limit)
    }
    
    func getTransactionDetails(hash: String, network: Network) -> Observable<Transaction> {
        // Check if API Key is available
        guard APIKeys.hasEtherscanKey else {
            return Observable.error(WalletError.networkError("No API key available"))
        }
        
        // TODO: Implement real transaction details query
        return Observable.error(WalletError.networkError("Transaction details not implemented"))
    }
    
    private func generateMockTransactions(address: String, network: Network, count: Int) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for i in 0..<count {
            let isInbound = i % 3 == 0
            let currencies: [Currency] = [.eth, .usdt, .usdc]
            let currency = currencies[i % currencies.count]
            
            let transaction = Transaction(
                hash: "0x\(String(repeating: "\(i)", count: 64))",
                from: isInbound ? "0x1234567890123456789012345678901234567890" : address,
                to: isInbound ? address : "0x1234567890123456789012345678901234567890",
                amount: Decimal(string: "\(Double.random(in: 0.01...1.0))") ?? 0,
                currency: currency,
                gasUsed: Decimal(string: "21000") ?? 0,
                gasPrice: Decimal(string: "20000000000") ?? 0,
                status: i % 10 == 0 ? .pending : .success,
                direction: isInbound ? .inbound : .outbound,
                timestamp: Date().addingTimeInterval(-Double(i * 3600)), // One transaction per hour
                blockNumber: 12345678 - i,
                network: network
            )
            
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    private func mockTransactionDetails(hash: String, network: Network) -> Transaction {
        return Transaction(
            hash: hash,
            from: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            to: "0x1234567890123456789012345678901234567890",
            amount: Decimal(string: "0.1") ?? 0,
            currency: Currency.eth,
            gasUsed: Decimal(string: "21000") ?? 0,
            gasPrice: Decimal(string: "20000000000") ?? 0, // 20 Gwei
            status: .success,
            direction: .outbound,
            timestamp: Date(),
            blockNumber: 12345678,
            network: network
        )
    }
    
    private func convertEtherscanTransaction(_ tx: EtherscanTransaction, network: Network) -> Transaction? {
        guard let blockNumber = Int(tx.blockNumber),
              let timestamp = Double(tx.timeStamp),
              let value = Decimal(string: tx.value),
              let gasUsed = Decimal(string: tx.gasUsed),
              let gasPrice = Decimal(string: tx.gasPrice) else {
            return nil
        }
        
        let status: TransactionStatus = tx.isError == "0" ? .success : .failed
        let direction: TransactionDirection = .outbound // Need to determine based on actual address
        
        return Transaction(
            hash: tx.hash,
            from: tx.from,
            to: tx.to,
            amount: value / Decimal(1_000_000_000_000_000_000), // Wei to ETH
            currency: Currency.eth,
            gasUsed: gasUsed,
            gasPrice: gasPrice,
            status: status,
            direction: direction,
            timestamp: Date(timeIntervalSince1970: timestamp),
            blockNumber: blockNumber,
            network: network
        )
    }
}
