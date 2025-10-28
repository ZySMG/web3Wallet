//
//  APIEndpoints.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import Alamofire

/// API endpoint definitions
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let encoding: ParameterEncoding
    let headers: HTTPHeaders?
}

/// Etherscan API endpoints
enum EtherscanEndpoint {
    case transactionList(address: String, startBlock: Int?, endBlock: Int?, page: Int, offset: Int, sort: String)
    
    var endpoint: APIEndpoint {
        switch self {
        case .transactionList(let address, let startBlock, let endBlock, let page, let offset, let sort):
            var parameters: [String: Any] = [
                "module": "account",
                "action": "txlist",
                "address": address,
                "page": page,
                "offset": offset,
                "sort": sort
            ]
            
            if let startBlock = startBlock {
                parameters["startblock"] = startBlock
            }
            if let endBlock = endBlock {
                parameters["endblock"] = endBlock
            }
            
            // Add API Key if available
            if APIKeys.hasEtherscanKey {
                parameters["apikey"] = APIKeys.etherscanKey(for: Network.sepolia)
            }
            
            return APIEndpoint(
                path: "",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: nil
            )
        }
    }
}

/// CoinGecko API endpoints
enum CoinGeckoEndpoint {
    case price(ids: [String], vsCurrencies: [String])
    case priceHistory(id: String, days: Int)
    
    var endpoint: APIEndpoint {
        switch self {
        case .price(let ids, let vsCurrencies):
            let parameters: [String: Any] = [
                "ids": ids.joined(separator: ","),
                "vs_currencies": vsCurrencies.joined(separator: ",")
            ]
            
            return APIEndpoint(
                path: "/api/v3/simple/price",
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
                path: "/api/v3/coins/\(id)/market_chart",
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: nil
            )
        }
    }
}
