//
//  Network.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Network configuration entity
/// Define supported blockchain networks and their configuration information
struct Network: Equatable, Codable {
    let id: String
    let name: String
    let chainId: Int
    let rpcURL: String
    let explorerBase: String
    let nativeCurrency: Currency
    let isTestnet: Bool
    
    static let ethereumMainnet = Network(
        id: "ethereum_mainnet",
        name: "Ethereum Mainnet",
        chainId: 1,
        rpcURL: "https://mainnet.infura.io/v3/1b7ed1f23d854cd99b816a1b6ea27b12",
        explorerBase: "https://etherscan.io",
        nativeCurrency: Currency(
            symbol: "ETH",
            name: "Ethereum",
            decimals: 18,
            contractAddress: nil
        ),
        isTestnet: false
    )
    
    static let sepolia = Network(
        id: "sepolia",
        name: "Sepolia Testnet",
        chainId: 11155111,
        rpcURL: "https://sepolia.infura.io/v3/1b7ed1f23d854cd99b816a1b6ea27b12",
        explorerBase: "https://sepolia.etherscan.io",
        nativeCurrency: Currency(
            symbol: "ETH",
            name: "Ethereum",
            decimals: 18,
            contractAddress: nil
        ),
        isTestnet: true
    )
    
    static let supportedNetworks: [Network] = [.ethereumMainnet, .sepolia]
}
