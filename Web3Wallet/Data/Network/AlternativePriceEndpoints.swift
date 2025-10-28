//
//  AlternativePriceEndpoints.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import Alamofire

/// Alternative.me API endpoints (Free, No API Key Required)
enum AlternativeEndpoint {
    case price(ids: [String])
    case priceHistory(id: String, days: Int)
    
    var endpoint: APIEndpoint {
        switch self {
        case .price(let ids):
            let parameters: [String: Any] = [
                "ids": ids.joined(separator: ","),
                "vs_currencies": "usd"
            ]
            
            return APIEndpoint(
                path: "/api/v1/simple/price",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: nil
            )
            
        case .priceHistory(let id, let days):
            let parameters: [String: Any] = [
                "vs_currency": "usd",
                "days": days
            ]
            
            return APIEndpoint(
                path: "/api/v1/coins/\(id)/market_chart",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: nil
            )
        }
    }
}

/// CoinMarketCap API endpoints
enum CoinMarketCapEndpoint {
    case price(ids: [String])
    case priceHistory(id: String, days: Int)
    
    var endpoint: APIEndpoint {
        switch self {
        case .price(let ids):
            let parameters: [String: Any] = [
                "id": ids.joined(separator: ","),
                "convert": "USD"
            ]
            
            return APIEndpoint(
                path: "/v1/cryptocurrency/quotes/latest",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: ["X-CMC_PRO_API_KEY": APIKeys.coinMarketCapKey]
            )
            
        case .priceHistory(let id, let days):
            let parameters: [String: Any] = [
                "id": id,
                "time_start": Calendar.current.date(byAdding: .day, value: -days, to: Date())?.timeIntervalSince1970 ?? 0,
                "time_end": Date().timeIntervalSince1970,
                "interval": days <= 7 ? "hourly" : "daily"
            ]
            
            return APIEndpoint(
                path: "/v1/cryptocurrency/quotes/historical",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: ["X-CMC_PRO_API_KEY": APIKeys.coinMarketCapKey]
            )
        }
    }
}

/// Moralis API endpoints
enum MoralisEndpoint {
    case price(ids: [String])
    case priceHistory(id: String, days: Int)
    
    var endpoint: APIEndpoint {
        switch self {
        case .price(let ids):
            let parameters: [String: Any] = [
                "chain": "eth",
                "addresses": ids.joined(separator: ",")
            ]
            
            return APIEndpoint(
                path: "/api/v2/erc20/\(ids.first ?? "")/price",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: ["X-API-Key": APIKeys.moralisKey]
            )
            
        case .priceHistory(let id, let days):
            let parameters: [String: Any] = [
                "chain": "eth",
                "address": id,
                "days": days
            ]
            
            return APIEndpoint(
                path: "/api/v2/erc20/\(id)/price/history",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: ["X-API-Key": APIKeys.moralisKey]
            )
        }
    }
}
