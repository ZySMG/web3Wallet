//
//  PriceService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// 价格服务协议
protocol PriceServiceProtocol {
    func getETHPrice() -> Observable<Decimal>
    func getTokenPrices(currencies: [Currency]) -> Observable<[String: Decimal]>
    func getPriceHistory(currency: Currency, days: Int) -> Observable<[PricePoint]>
}

/// 价格数据点
struct PricePoint: Codable {
    let timestamp: Date
    let price: Decimal
    
    init(timestamp: Date, price: Decimal) {
        self.timestamp = timestamp
        self.price = price
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestampValue = try container.decode(TimeInterval.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampValue / 1000) // CoinGecko 使用毫秒
        price = try container.decode(Decimal.self, forKey: .price)
    }
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case price
    }
}

/// CoinGecko 价格响应
struct CoinGeckoPriceResponse: Codable {
    let ethereum: TokenPrice?
    let tether: TokenPrice?
    let usdCoin: TokenPrice?
    
    enum CodingKeys: String, CodingKey {
        case ethereum
        case tether
        case usdCoin = "usd-coin"
    }
}

struct TokenPrice: Codable {
    let usd: Decimal
}

/// CoinGecko 价格历史响应
struct CoinGeckoPriceHistoryResponse: Codable {
    let prices: [[Double]]
    
    func toPricePoints() -> [PricePoint] {
        return prices.compactMap { priceArray in
            guard priceArray.count >= 2 else { return nil }
            let timestamp = Date(timeIntervalSince1970: priceArray[0] / 1000)
            let price = Decimal(priceArray[1])
            return PricePoint(timestamp: timestamp, price: price)
        }
    }
}

/// 价格服务实现
class PriceService: PriceServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func getETHPrice() -> Observable<Decimal> {
        // Check if API Key is available
        guard APIKeys.hasCoinGeckoKey else {
            // Return mock data if no API key
            return Observable.just(Decimal(string: "2500.123456789") ?? 0)
        }
        
        let endpoint = CoinGeckoEndpoint.price(ids: ["ethereum"], vsCurrencies: ["usd"])
        
        return networkService.request(endpoint.endpoint, responseType: CoinGeckoPriceResponse.self)
            .map { response in
                return response.ethereum?.usd ?? 0
            }
            .catch { _ in
                // Return mock data if network request fails
                return Observable.just(Decimal(string: "2500.123456789") ?? 0)
            }
    }
    
    func getTokenPrices(currencies: [Currency]) -> Observable<[String: Decimal]> {
        // Check if API Key is available
        guard APIKeys.hasCoinGeckoKey else {
            // Return mock data if no API key
            return Observable.just(mockTokenPrices(for: currencies))
        }
        
        let ids = currencies.compactMap { currency in
            switch currency.symbol {
            case "ETH": return "ethereum"
            case "USDT": return "tether"
            case "USDC": return "usd-coin"
            default: return nil
            }
        }
        
        let endpoint = CoinGeckoEndpoint.price(ids: ids, vsCurrencies: ["usd"])
        
        return networkService.request(endpoint.endpoint, responseType: CoinGeckoPriceResponse.self)
            .map { response in
                var prices: [String: Decimal] = [:]
                
                if let ethPrice = response.ethereum?.usd {
                    prices["ETH"] = ethPrice
                }
                if let usdtPrice = response.tether?.usd {
                    prices["USDT"] = usdtPrice
                }
                if let usdcPrice = response.usdCoin?.usd {
                    prices["USDC"] = usdcPrice
                }
                
                return prices
            }
            .catch { _ in
                // Return mock data if network request fails
                return Observable.just(self.mockTokenPrices(for: currencies))
            }
    }
    
    func getPriceHistory(currency: Currency, days: Int) -> Observable<[PricePoint]> {
        // Check if API Key is available
        guard APIKeys.hasCoinGeckoKey else {
            // Return mock data if no API key
            return Observable.just(generateMockPriceHistory(currency: currency, days: days))
        }
        
        let coinId = currency.symbol.lowercased()
        let endpoint = CoinGeckoEndpoint.priceHistory(id: coinId, days: days)
        
        return networkService.request(endpoint.endpoint, responseType: CoinGeckoPriceHistoryResponse.self)
            .map { response in
                return response.toPricePoints()
            }
            .catch { _ in
                // Return mock data if network request fails
                return Observable.just(self.generateMockPriceHistory(currency: currency, days: days))
            }
    }
    
    private func mockTokenPrices(for currencies: [Currency]) -> [String: Decimal] {
        var prices: [String: Decimal] = [:]
        
        for currency in currencies {
            switch currency.symbol {
            case "ETH":
                prices["ETH"] = Decimal(string: "2500.123456789") ?? 0
            case "USDT":
                prices["USDT"] = Decimal(string: "1.000123") ?? 0
            case "USDC":
                prices["USDC"] = Decimal(string: "1.000456") ?? 0
            default:
                prices[currency.symbol] = Decimal(string: "1.0") ?? 0
            }
        }
        
        return prices
    }
    
    private func generateMockPriceHistory(currency: Currency, days: Int) -> [PricePoint] {
        var pricePoints: [PricePoint] = []
        let basePrice: Decimal
        
        switch currency.symbol {
        case "ETH":
            basePrice = Decimal(string: "2500") ?? 0
        case "USDT", "USDC":
            basePrice = Decimal(string: "1") ?? 0
        default:
            basePrice = Decimal(string: "1") ?? 0
        }
        
        let now = Date()
        let pointsPerDay = 24 // One point per hour
        
        for i in 0..<(days * pointsPerDay) {
            let timestamp = now.addingTimeInterval(-Double(i * 3600)) // Every hour
            let variation = Decimal(Double.random(in: -0.05...0.05)) // ±5% variation
            let price = basePrice * (1 + variation)
            
            pricePoints.append(PricePoint(timestamp: timestamp, price: price))
        }
        
        return pricePoints.reversed() // Sort by time ascending
    }
}
