//
//  FetchTxHistoryUseCase.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// 获取交易历史用例
/// 负责获取钱包的交易记录
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
        
        // 检查缓存
        if let cachedTransactions: [Transaction] = cacheService.get(key: cacheKey) {
            return Observable.just(cachedTransactions)
        }
        
        // 获取交易历史
        return txService.getTransactionHistory(address: wallet.address, network: wallet.network, limit: limit)
            .do(onNext: { transactions in
                // 缓存结果
                self.cacheService.set(key: cacheKey, value: transactions, ttl: 90) // 90秒缓存
            })
    }
}
