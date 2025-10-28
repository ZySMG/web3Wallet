//
//  ResolveBalancesUseCase.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// 解析余额用例
/// 负责获取钱包的余额信息
protocol ResolveBalancesUseCaseProtocol {
    func resolveBalances(for wallet: Wallet, currencies: [Currency]) -> Observable<[Balance]>
}

class ResolveBalancesUseCase: ResolveBalancesUseCaseProtocol {
    
    private let ethereumService: EthereumServiceProtocol
    private let cacheService: CacheServiceProtocol
    
    init(ethereumService: EthereumServiceProtocol, cacheService: CacheServiceProtocol) {
        self.ethereumService = ethereumService
        self.cacheService = cacheService
    }
    
    func resolveBalances(for wallet: Wallet, currencies: [Currency]) -> Observable<[Balance]> {
        let cacheKey = "balances_\(wallet.address)_\(wallet.network.chainId)"
        
        // 检查缓存
        if let cachedBalances: [Balance] = cacheService.get(key: cacheKey) {
            return Observable.just(cachedBalances)
        }
        
        // 确保ETH、USDC、USDT始终在列表中，即使余额为0
        var currenciesToFetch = currencies
        let alwaysIncludeSymbols = ["ETH", "USDC", "USDT"]
        
        for symbol in alwaysIncludeSymbols {
            if !currenciesToFetch.contains(where: { $0.symbol == symbol }) {
                switch symbol {
                case "ETH":
                    currenciesToFetch.append(Currency.eth)
                case "USDC":
                    currenciesToFetch.append(Currency.usdc)
                case "USDT":
                    currenciesToFetch.append(Currency.usdt)
                default:
                    break
                }
            }
        }
        
        // 获取余额
        return Observable.combineLatest(
            currenciesToFetch.map { currency in
                ethereumService.getBalance(address: wallet.address, currency: currency, network: wallet.network)
                    .map { amount in
                        Balance(currency: currency, amount: amount)
                    }
            }
        )
        .do(onNext: { balances in
            // 缓存结果
            self.cacheService.set(key: cacheKey, value: balances, ttl: 20) // 20秒缓存
        })
    }
}
