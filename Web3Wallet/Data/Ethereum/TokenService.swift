//
//  TokenService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// Token service protocol
protocol TokenServiceProtocol {
    func getTokenBalance(address: String, tokenAddress: String, network: Network) -> Observable<Decimal>
    func getTokenInfo(tokenAddress: String, network: Network) -> Observable<TokenInfo>
}

/// Token information
struct TokenInfo: Codable {
    let address: String
    let symbol: String
    let name: String
    let decimals: Int
    let totalSupply: Decimal?
}

/// Token service implementation
class TokenService: TokenServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func getTokenBalance(address: String, tokenAddress: String, network: Network) -> Observable<Decimal> {
        // Check if API Key is available
        guard APIKeys.hasEtherscanKey else {
            // Return mock data if no API key
            return Observable.just(mockTokenBalance(for: tokenAddress))
        }
        
        // TODO: Implement real ERC-20 balanceOf call
        return Observable.just(mockTokenBalance(for: tokenAddress))
    }
    
    func getTokenInfo(tokenAddress: String, network: Network) -> Observable<TokenInfo> {
        // TODO: Implement real ERC-20 token info query
        return Observable.just(mockTokenInfo(for: tokenAddress))
    }
    
    private func mockTokenBalance(for tokenAddress: String) -> Decimal {
        // Return mock balance for testing
        switch tokenAddress.lowercased() {
        case "0xdac17f958d2ee523a2206206994597c13d831ec7": // USDT
            return Decimal(string: "1000.123456") ?? 0
        case "0xa0b86a33e6441b8c4c8c0e1234567890abcdef12": // USDC
            return Decimal(string: "500.654321") ?? 0
        default:
            return Decimal(string: "100.000000") ?? 0
        }
    }
    
    private func mockTokenInfo(for tokenAddress: String) -> TokenInfo {
        switch tokenAddress.lowercased() {
        case "0xdac17f958d2ee523a2206206994597c13d831ec7":
            return TokenInfo(
                address: tokenAddress,
                symbol: "USDT",
                name: "Tether USD",
                decimals: 6,
                totalSupply: nil
            )
        case "0xa0b86a33e6441b8c4c8c0e1234567890abcdef12":
            return TokenInfo(
                address: tokenAddress,
                symbol: "USDC",
                name: "USD Coin",
                decimals: 6,
                totalSupply: nil
            )
        default:
            return TokenInfo(
                address: tokenAddress,
                symbol: "UNKNOWN",
                name: "Unknown Token",
                decimals: 18,
                totalSupply: nil
            )
        }
    }
}
