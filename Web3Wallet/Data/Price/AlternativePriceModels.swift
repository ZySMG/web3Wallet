//
//  AlternativePriceModels.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

// MARK: - Alternative.me Response Models

struct AlternativePriceResponse: Codable {
    let ethereum: AlternativePriceData?
    let tether: AlternativePriceData?
    let usd_coin: AlternativePriceData?
    
    enum CodingKeys: String, CodingKey {
        case ethereum
        case tether
        case usd_coin = "usd-coin"
    }
}

struct AlternativePriceData: Codable {
    let usd: Double
}

struct AlternativePriceHistoryResponse: Codable {
    let prices: [[Double]]
    
    func toPricePoints() -> [PricePoint] {
        return prices.compactMap { priceData in
            guard priceData.count >= 2 else { return nil }
            let timestamp = Date(timeIntervalSince1970: priceData[0] / 1000)
            let price = Decimal(priceData[1])
            return PricePoint(timestamp: timestamp, price: price)
        }
    }
}

// MARK: - CoinMarketCap Response Models

struct CoinMarketCapPriceResponse: Codable {
    let data: [String: CoinMarketCapPriceData]
}

struct CoinMarketCapPriceData: Codable {
    let id: Int
    let name: String
    let symbol: String
    let quote: CoinMarketCapQuote
}

struct CoinMarketCapQuote: Codable {
    let USD: CoinMarketCapUSDPrice
}

struct CoinMarketCapUSDPrice: Codable {
    let price: Double
    let last_updated: String
}

struct CoinMarketCapPriceHistoryResponse: Codable {
    let data: CoinMarketCapPriceHistoryData
}

struct CoinMarketCapPriceHistoryData: Codable {
    let quotes: [CoinMarketCapHistoricalQuote]
}

struct CoinMarketCapHistoricalQuote: Codable {
    let timestamp: String
    let quote: CoinMarketCapQuote
}

// MARK: - Moralis Response Models

struct MoralisPriceResponse: Codable {
    let usdPrice: Double
    let tokenAddress: String
    let tokenName: String
    let tokenSymbol: String
    let tokenLogo: String?
    let tokenDecimals: Int
    let nativePrice: MoralisNativePrice?
}

struct MoralisNativePrice: Codable {
    let value: String
    let decimals: Int
    let name: String
    let symbol: String
}

struct MoralisPriceHistoryResponse: Codable {
    let result: [MoralisPriceHistoryItem]
}

struct MoralisPriceHistoryItem: Codable {
    let timestamp: String
    let value: String
    let price: Double
}
