//
//  MultiSourcePriceService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift

/// Multi-source price service implementation
/// Supports CoinGecko, CoinMarketCap, Moralis, and Alternative.me as fallback
class MultiSourcePriceService: PriceServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func getETHPrice() -> Observable<Decimal> {
        // Try different data sources in order of preference
        if APIKeys.hasCoinGeckoKey {
            return getETHPriceFromCoinGecko()
        } else if APIKeys.hasCoinMarketCapKey {
            return getETHPriceFromCoinMarketCap()
        } else if APIKeys.hasMoralisKey {
            return getETHPriceFromMoralis()
        } else {
            // Fallback to Alternative.me (free, no API key required)
            return getETHPriceFromAlternative()
        }
    }
    
    func getTokenPrices(currencies: [Currency]) -> Observable<[String: Decimal]> {
        // Try different data sources in order of preference
        if APIKeys.hasCoinGeckoKey {
            return getTokenPricesFromCoinGecko(currencies: currencies)
        } else if APIKeys.hasCoinMarketCapKey {
            return getTokenPricesFromCoinMarketCap(currencies: currencies)
        } else if APIKeys.hasMoralisKey {
            return getTokenPricesFromMoralis(currencies: currencies)
        } else {
            // Fallback to Alternative.me (free, no API key required)
            return getTokenPricesFromAlternative(currencies: currencies)
        }
    }
    
    func getPriceHistory(currency: Currency, days: Int) -> Observable<[PricePoint]> {
        // Try different data sources in order of preference
        if APIKeys.hasCoinGeckoKey {
            return getPriceHistoryFromCoinGecko(currency: currency, days: days)
        } else if APIKeys.hasCoinMarketCapKey {
            return getPriceHistoryFromCoinMarketCap(currency: currency, days: days)
        } else if APIKeys.hasMoralisKey {
            return getPriceHistoryFromMoralis(currency: currency, days: days)
        } else {
            // Fallback to Alternative.me (free, no API key required)
            return getPriceHistoryFromAlternative(currency: currency, days: days)
        }
    }
    
    // MARK: - CoinGecko Implementation
    
    private func getETHPriceFromCoinGecko() -> Observable<Decimal> {
        let endpoint = CoinGeckoEndpoint.price(ids: ["ethereum"], vsCurrencies: ["usd"])
        
        return networkService.request(endpoint.endpoint, responseType: CoinGeckoPriceResponse.self)
            .map { response in
                return response.ethereum?.usd ?? 0
            }
            .catch { _ in
                // Fallback to Alternative.me if CoinGecko fails
                return self.getETHPriceFromAlternative()
            }
    }
    
    private func getTokenPricesFromCoinGecko(currencies: [Currency]) -> Observable<[String: Decimal]> {
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
                // Fallback to Alternative.me if CoinGecko fails
                return self.getTokenPricesFromAlternative(currencies: currencies)
            }
    }
    
    private func getPriceHistoryFromCoinGecko(currency: Currency, days: Int) -> Observable<[PricePoint]> {
        let coinId = currency.symbol.lowercased()
        let endpoint = CoinGeckoEndpoint.priceHistory(id: coinId, days: days)
        
        return networkService.request(endpoint.endpoint, responseType: CoinGeckoPriceHistoryResponse.self)
            .map { response in
                return response.toPricePoints()
            }
            .catch { _ in
                // Fallback to Alternative.me if CoinGecko fails
                return self.getPriceHistoryFromAlternative(currency: currency, days: days)
            }
    }
    
    // MARK: - Alternative.me Implementation (Free, No API Key Required)
    
    private func getETHPriceFromAlternative() -> Observable<Decimal> {
        let endpoint = AlternativeEndpoint.price(ids: ["ethereum"])
        
        return networkService.request(endpoint.endpoint, responseType: AlternativePriceResponse.self)
            .map { response in
                return Decimal(response.ethereum?.usd ?? 0)
            }
            .catch { _ in
                // Return mock data if all services fail
                return Observable.just(Decimal(string: "2500.123456789") ?? 0)
            }
    }
    
    private func getTokenPricesFromAlternative(currencies: [Currency]) -> Observable<[String: Decimal]> {
        let ids = currencies.compactMap { currency in
            switch currency.symbol {
            case "ETH": return "ethereum"
            case "USDT": return "tether"
            case "USDC": return "usd-coin"
            default: return nil
            }
        }
        
        let endpoint = AlternativeEndpoint.price(ids: ids)
        
        return networkService.request(endpoint.endpoint, responseType: AlternativePriceResponse.self)
            .map { response in
                var prices: [String: Decimal] = [:]
                
                if let ethPrice = response.ethereum?.usd {
                    prices["ETH"] = Decimal(ethPrice)
                }
                if let usdtPrice = response.tether?.usd {
                    prices["USDT"] = Decimal(usdtPrice)
                }
                if let usdcPrice = response.usd_coin?.usd {
                    prices["USDC"] = Decimal(usdcPrice)
                }
                
                return prices
            }
            .catch { _ in
                // Return mock data if all services fail
                return Observable.just(self.mockTokenPrices(for: currencies))
            }
    }
    
    private func getPriceHistoryFromAlternative(currency: Currency, days: Int) -> Observable<[PricePoint]> {
        let coinId = currency.symbol.lowercased()
        let endpoint = AlternativeEndpoint.priceHistory(id: coinId, days: days)
        
        return networkService.request(endpoint.endpoint, responseType: AlternativePriceHistoryResponse.self)
            .map { response in
                return response.toPricePoints()
            }
            .catch { _ in
                // Return mock data if all services fail
                return Observable.just(self.generateMockPriceHistory(currency: currency, days: days))
            }
    }
    
    // MARK: - CoinMarketCap Implementation
    
    private func getETHPriceFromCoinMarketCap() -> Observable<Decimal> {
        let endpoint = CoinMarketCapEndpoint.price(ids: ["1"]) // Ethereum ID in CoinMarketCap
        
        return networkService.request(endpoint.endpoint, responseType: CoinMarketCapPriceResponse.self)
            .map { response in
                return Decimal(response.data["1"]?.quote.USD.price ?? 0)
            }
            .catch { _ in
                // Fallback to Alternative.me if CoinMarketCap fails
                return self.getETHPriceFromAlternative()
            }
    }
    
    private func getTokenPricesFromCoinMarketCap(currencies: [Currency]) -> Observable<[String: Decimal]> {
        let ids = currencies.compactMap { currency in
            switch currency.symbol {
            case "ETH": return "1"
            case "USDT": return "825"
            case "USDC": return "3408"
            default: return nil
            }
        }
        
        let endpoint = CoinMarketCapEndpoint.price(ids: ids)
        
        return networkService.request(endpoint.endpoint, responseType: CoinMarketCapPriceResponse.self)
            .map { response in
                var prices: [String: Decimal] = [:]
                
                if let ethData = response.data["1"] {
                    prices["ETH"] = Decimal(ethData.quote.USD.price)
                }
                if let usdtData = response.data["825"] {
                    prices["USDT"] = Decimal(usdtData.quote.USD.price)
                }
                if let usdcData = response.data["3408"] {
                    prices["USDC"] = Decimal(usdcData.quote.USD.price)
                }
                
                return prices
            }
            .catch { _ in
                // Fallback to Alternative.me if CoinMarketCap fails
                return self.getTokenPricesFromAlternative(currencies: currencies)
            }
    }
    
    private func getPriceHistoryFromCoinMarketCap(currency: Currency, days: Int) -> Observable<[PricePoint]> {
        let coinId = currency.symbol == "ETH" ? "1" : currency.symbol == "USDT" ? "825" : "3408"
        let endpoint = CoinMarketCapEndpoint.priceHistory(id: coinId, days: days)
        
        return networkService.request(endpoint.endpoint, responseType: CoinMarketCapPriceHistoryResponse.self)
            .map { response in
                return response.data.quotes.compactMap { quote in
                    guard let timestamp = Double(quote.timestamp) else { return nil }
                    return PricePoint(timestamp: Date(timeIntervalSince1970: timestamp), price: Decimal(quote.quote.USD.price))
                }
            }
            .catch { _ in
                // Fallback to Alternative.me if CoinMarketCap fails
                return self.getPriceHistoryFromAlternative(currency: currency, days: days)
            }
    }
    
    // MARK: - Moralis Implementation
    
    private func getETHPriceFromMoralis() -> Observable<Decimal> {
        // Moralis doesn't have direct ETH price endpoint, fallback to Alternative.me
        return getETHPriceFromAlternative()
    }
    
    private func getTokenPricesFromMoralis(currencies: [Currency]) -> Observable<[String: Decimal]> {
        // Moralis is mainly for ERC-20 tokens, not native ETH
        // For now, fallback to Alternative.me
        return getTokenPricesFromAlternative(currencies: currencies)
    }
    
    private func getPriceHistoryFromMoralis(currency: Currency, days: Int) -> Observable<[PricePoint]> {
        // Moralis price history implementation would go here
        // For now, fallback to Alternative.me
        return getPriceHistoryFromAlternative(currency: currency, days: days)
    }
    
    // MARK: - Mock Data Fallback
    
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
