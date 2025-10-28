//
//  APIKeys.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// API Keys configuration for third-party services
struct APIKeys {
    
    // MARK: - Etherscan API Keys
    /// Etherscan API Key for Ethereum mainnet
    /// Get your free API key from: https://etherscan.io/apis
    static let etherscanMainnetKey = "ZPGF1565E6Q812RKIHKCJNC6GGV763E61H"
    
    /// Etherscan API Key for Sepolia testnet
    /// Get your free API key from: https://sepolia.etherscan.io/apis
    static let etherscanSepoliaKey = "ZPGF1565E6Q812RKIHKCJNC6GGV763E61H"
    
    // MARK: - CoinGecko API Keys
    /// CoinGecko API Key for price data
    /// Get your free API key from: https://www.coingecko.com/en/api
    static let coinGeckoKey = ""
    
    // MARK: - Alchemy API Keys
    /// Alchemy API Key for Ethereum mainnet
    /// Get your free API key from: https://www.alchemy.com/
    static let alchemyMainnetKey = "JML8wnqevcICArkIob7z8wKnvi5hq0rD"
    
    /// Alchemy API Key for Sepolia testnet
    static let alchemySepoliaKey = "JML8wnqevcICArkIob7z8wKnvi5hq0rD"
    
    // MARK: - Infura API Keys
    /// Infura API Key for Ethereum mainnet
    /// Get your free API key from: https://infura.io/
    static let infuraMainnetKey = "1b7ed1f23d854cd99b816a1b6ea27b12"
    
    /// Infura API Key for Sepolia testnet
    static let infuraSepoliaKey = "1b7ed1f23d854cd99b816a1b6ea27b12"
    
    // MARK: - CoinMarketCap API Keys
    /// CoinMarketCap API Key for price data
    /// Get your free API key from: https://coinmarketcap.com/api/
    static let coinMarketCapKey = "d4f35e72749640d3a0ac1d9f99f9f85e"
    
    // MARK: - Moralis API Keys
    /// Moralis API Key for price data
    /// Get your free API key from: https://moralis.io/
    static let moralisKey = ""
    
    // MARK: - Helper Properties
    
    /// Check if Etherscan API key is available
    static var hasEtherscanKey: Bool {
        return !etherscanMainnetKey.isEmpty || !etherscanSepoliaKey.isEmpty
    }
    
    /// Check if CoinGecko API key is available
    static var hasCoinGeckoKey: Bool {
        return !coinGeckoKey.isEmpty
    }
    
    /// Check if CoinMarketCap API key is available
    static var hasCoinMarketCapKey: Bool {
        return !coinMarketCapKey.isEmpty
    }
    
    /// Check if Moralis API key is available
    static var hasMoralisKey: Bool {
        return !moralisKey.isEmpty
    }
    
    /// Check if Alchemy API key is available
    static var hasAlchemyKey: Bool {
        return !alchemyMainnetKey.isEmpty || !alchemySepoliaKey.isEmpty
    }
    
    /// Check if Infura API key is available
    static var hasInfuraKey: Bool {
        return !infuraMainnetKey.isEmpty || !infuraSepoliaKey.isEmpty
    }
    
    /// Get Etherscan API key for specific network
    static func etherscanKey(for network: Network) -> String {
        switch network.id {
        case "ethereum_mainnet":
            return etherscanMainnetKey
        case "sepolia":
            return etherscanSepoliaKey
        default:
            return etherscanSepoliaKey // Default to testnet
        }
    }
    
    /// Get Alchemy API key for specific network
    static func alchemyKey(for network: Network) -> String {
        switch network.id {
        case "ethereum_mainnet":
            return alchemyMainnetKey
        case "sepolia":
            return alchemySepoliaKey
        default:
            return alchemySepoliaKey // Default to testnet
        }
    }
    
    /// Get Infura API key for specific network
    static func infuraKey(for network: Network) -> String {
        switch network.id {
        case "ethereum_mainnet":
            return infuraMainnetKey
        case "sepolia":
            return infuraSepoliaKey
        default:
            return infuraSepoliaKey // Default to testnet
        }
    }
}

/// API Configuration Guide
/// 
/// To use real data instead of mock data, you need to obtain API keys from the following services:
///
/// 1. Etherscan (Required for transaction history and balance queries)
///    - Mainnet: https://etherscan.io/apis
///    - Sepolia: https://sepolia.etherscan.io/apis
///    - Free tier: 5 calls/second, 100,000 calls/day
///
/// 2. CoinGecko (Required for price data)
///    - https://www.coingecko.com/en/api
///    - Free tier: 10-50 calls/minute
///
/// 3. Alchemy (Optional, for enhanced Ethereum data)
///    - https://www.alchemy.com/
///    - Free tier: 300M compute units/month
///
/// 4. Infura (Optional, alternative to Alchemy)
///    - https://infura.io/
///    - Free tier: 100,000 requests/day
///
/// Instructions:
/// 1. Sign up for accounts on the services you want to use
/// 2. Generate API keys from their dashboards
/// 3. Replace the empty strings above with your actual API keys
/// 4. The app will automatically use real data when API keys are provided
/// 5. If no API keys are provided, the app will use mock data for development
///
/// Security Note:
/// - Never commit API keys to version control
/// - Consider using environment variables or secure storage for production
/// - Monitor your API usage to avoid exceeding free tier limits
