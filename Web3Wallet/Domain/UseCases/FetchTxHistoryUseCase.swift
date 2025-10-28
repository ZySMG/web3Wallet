//
//  FetchTxHistoryUseCase.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// Fetch transaction history use case
/// Responsible for fetching wallet transaction records
protocol FetchTxHistoryUseCaseProtocol {
    func fetchTransactionHistory(for wallet: Wallet, limit: Int) -> Observable<[Transaction]>
}

class FetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol {
    
    private let txService: TxServiceProtocol
    private let cacheService: CacheServiceProtocol
    
    init(txService: TxServiceProtocol, cacheService: CacheServiceProtocol) {
        self.txService = txService
        self.cacheService = cacheService
    }
    
    func fetchTransactionHistory(for wallet: Wallet, limit: Int = 10) -> Observable<[Transaction]> {
        let cacheKey = "tx_history_\(wallet.address)_\(wallet.network.chainId)_\(limit)"
        
        // Check cache
        if let cachedTransactions: [Transaction] = cacheService.get(key: cacheKey) {
            return Observable.just(cachedTransactions)
        }
        
        // Fetch transaction history
        return txService.getTransactionHistory(address: wallet.address, network: wallet.network, limit: limit)
            .do(onNext: { transactions in
                // Cache results
                self.cacheService.set(key: cacheKey, value: transactions, ttl: 90) // 90秒缓存
            })
    }
}
