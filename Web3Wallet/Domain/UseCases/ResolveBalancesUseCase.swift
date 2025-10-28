//
//  ResolveBalancesUseCase.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// Resolve balances use case
/// Responsible for getting wallet balance information
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
        
        // Check cache
        if let cachedBalances: [Balance] = cacheService.get(key: cacheKey) {
            return Observable.just(cachedBalances)
        }
        
        // Ensure ETH, USDC, USDT are always in the list, even with 0 balance
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
        
        // Get balances
        return Observable.combineLatest(
            currenciesToFetch.map { currency in
                ethereumService.getBalance(address: wallet.address, currency: currency, network: wallet.network)
                    .map { amount in
                        Balance(currency: currency, amount: amount)
                    }
            }
        )
        .do(onNext: { balances in
            // Cache result
            self.cacheService.set(key: cacheKey, value: balances, ttl: 20) // 20秒缓存
        })
    }
}
