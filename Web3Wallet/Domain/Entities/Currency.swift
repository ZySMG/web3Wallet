//
//  Currency.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Currency entity
/// Define basic information for tokens, including native coins and ERC-20 tokens
struct Currency: Equatable, Codable {
    let symbol: String
    let name: String
    let decimals: Int
    let contractAddress: String?
    
    /// Whether it is a native coin (ETH)
    var isNative: Bool {
        return contractAddress == nil
    }
    
    /// Format display name
    var displayName: String {
        return "\(name) (\(symbol))"
    }
    
    static let eth = Currency(
        symbol: "ETH",
        name: "Ethereum",
        decimals: 18,
        contractAddress: nil
    )
    
    static let usdt = Currency(
        symbol: "USDT",
        name: "Tether USD (Testnet)",
        decimals: 6,
        contractAddress: "0xb38e0ba5aea889652b64ad38d624848896dcb089" // Faucet: https://developer.bitaps.com/faucet, but has issues, cannot guarantee if it's real deposit, currently can use Circle's USDC test stablecoin, more reliable
    )
    
    static let usdc = Currency(
        symbol: "USDC",
        name: "USD Coin",
        decimals: 6,
        contractAddress: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238" // USDC faucet address: https://faucet.circle.com/
    )
    
    static let supportedCurrencies: [Currency] = [.eth, .usdc, .usdt]
}
