//
//  EtherscanV2Service.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

/// Etherscan API V2 service
/// Uses unified V2 endpoint (https://api.etherscan.io/v2/api) with mandatory chainid (e.g., 11155111 for Sepolia).
class EtherscanV2Service {
    
    private let apiKey: String
    private let baseURL: String
    private let chainId: String
    
    init(apiKey: String, chainId: String = "11155111", baseURL: String = "https://api.etherscan.io/v2/api") {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.chainId = chainId
    }
    
    /// Get ETH balance (V2 API)
    func getETHBalance(address: String, chainId: Int) -> Observable<String> {
        return Observable.create { observer in
            let url = self.baseURL
            let parameters: [String: Any] = [
                "apikey": self.apiKey,
                "chainid": self.chainId,
                "module": "account",
                "action": "balance",
                "address": address,
                "tag": "latest"
            ]
            
            print("🔍 Etherscan V2 - ETH Balance Query")
            print("📡 URL: \(url)")
            print("📍 Address: \(address)")
            
            AF.request(url, method: .get, parameters: parameters)
                .validate()
                .responseJSON { response in
                    print("📊 Response Status: \(response.response?.statusCode ?? 0)")
                    
                    switch response.result {
                    case .success(let json):
                        print("✅ Raw Response: \(json)")
                        
                        if let dict = json as? [String: Any] {
                            if let status = dict["status"] as? String {
                                if status == "1" {
                                    if let result = dict["result"] as? String {
                                        print("✅ ETH Balance Raw: \(result)")
                                        observer.onNext(result)
                                        observer.onCompleted()
                                    } else {
                                        print("❌ Invalid result format")
                                        observer.onNext("0")
                                        observer.onCompleted()
                                    }
                                } else {
                                    let message = dict["message"] as? String ?? "Unknown error"
                                    print("❌ API Error: \(message)")
                                    observer.onNext("0")
                                    observer.onCompleted()
                                }
                            } else {
                                print("❌ Invalid response format")
                                observer.onNext("0")
                                observer.onCompleted()
                            }
                        } else {
                            print("❌ Invalid JSON response")
                            observer.onNext("0")
                            observer.onCompleted()
                        }
                        
                    case .failure(let error):
                        print("❌ Network Error: \(error.localizedDescription)")
                        observer.onNext("0")
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// Get token balance (V2 API)
    func getTokenBalance(address: String, contractAddress: String, chainId: Int, decimals: Int = 18) -> Observable<String> {
        return Observable.create { observer in
            let url = self.baseURL
            let parameters: [String: Any] = [
                "apikey": self.apiKey,
                "chainid": self.chainId,
                "module": "account",
                "action": "tokenbalance",
                "contractaddress": contractAddress,
                "address": address
            ]
            
            print("🔍 Etherscan V2 - Token Balance Query")
            print("📡 URL: \(url)")
            print("🪙 Contract: \(contractAddress)")
            print("📍 Address: \(address)")
            
            AF.request(url, method: .get, parameters: parameters)
                .validate()
                .responseJSON { response in
                    print("📊 Response Status: \(response.response?.statusCode ?? 0)")
                    
                    switch response.result {
                    case .success(let json):
                        print("✅ Raw Response: \(json)")
                        
                        if let dict = json as? [String: Any] {
                            if let status = dict["status"] as? String {
                                if status == "1" {
                                    if let result = dict["result"] as? String {
                                        print("✅ Token Balance Raw: \(result)")
                                        observer.onNext(result)
                                        observer.onCompleted()
                                    } else {
                                        print("❌ Invalid result format")
                                        observer.onNext("0")
                                        observer.onCompleted()
                                    }
                                } else {
                                    let message = dict["message"] as? String ?? "Unknown error"
                                    print("❌ API Error: \(message)")
                                    observer.onNext("0")
                                    observer.onCompleted()
                                }
                            } else {
                                print("❌ Invalid response format")
                                observer.onNext("0")
                                observer.onCompleted()
                            }
                        } else {
                            print("❌ Invalid JSON response")
                            observer.onNext("0")
                            observer.onCompleted()
                        }
                        
                    case .failure(let error):
                        print("❌ Network Error: \(error.localizedDescription)")
                        observer.onNext("0")
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// Get transaction history (V2 API)
    func getTransactionHistory(address: String, limit: Int = 10) -> Observable<[Transaction]> {
        return Observable.create { observer in
            let url = self.baseURL
            let parameters: [String: Any] = [
                "apikey": self.apiKey,
                "chainid": self.chainId,
                "module": "account",
                "action": "txlist",
                "address": address,
                "startblock": 0,
                "endblock": 99999999,
                "page": 1,
                "offset": limit,
                "sort": "desc"
            ]
            
            print("🔍 Etherscan V2 - Transaction History Query")
            print("📡 URL: \(url)")
            print("📍 Address: \(address)")
            print("📄 Limit: \(limit)")
            
            AF.request(url, method: .get, parameters: parameters)
                .validate()
                .responseJSON { response in
                    print("📊 Response Status: \(response.response?.statusCode ?? 0)")
                    
                    switch response.result {
                    case .success(let json):
                        print("✅ Raw Response: \(json)")
                        
                        if let dict = json as? [String: Any] {
                            if let status = dict["status"] as? String {
                                if status == "1" {
                                    if let result = dict["result"] as? [[String: Any]] {
                                        let transactions = result.compactMap { txDict in
                                            self.convertToTransaction(txDict, ownerAddress: address)
                                        }
                                        print("✅ Found \(transactions.count) transactions")
                                        observer.onNext(transactions)
                                        observer.onCompleted()
                                    } else {
                                        print("❌ Invalid result format")
                                        observer.onNext([])
                                        observer.onCompleted()
                                    }
                                } else {
                                    let message = dict["message"] as? String ?? "Unknown error"
                                    print("❌ API Error: \(message)")
                                    observer.onNext([])
                                    observer.onCompleted()
                                }
                            } else {
                                print("❌ Invalid response format")
                                observer.onNext([])
                                observer.onCompleted()
                            }
                        } else {
                            print("❌ Invalid JSON response")
                            observer.onNext([])
                            observer.onCompleted()
                        }
                        
                    case .failure(let error):
                        print("❌ Network Error: \(error.localizedDescription)")
                        observer.onNext([])
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// Get ERC-20 token transfer history
    func getTokenTransactionHistory(address: String, limit: Int = 10) -> Observable<[Transaction]> {
        return Observable.create { observer in
            let url = self.baseURL
            let parameters: [String: Any] = [
                "apikey": self.apiKey,
                "chainid": self.chainId,
                "module": "account",
                "action": "tokentx",
                "address": address,
                "startblock": 0,
                "endblock": 99999999,
                "page": 1,
                "offset": limit,
                "sort": "desc"
            ]
            
            print("🔍 Etherscan V2 - Token Transaction Query")
            print("📡 URL: \(url)")
            print("📍 Address: \(address)")
            print("📄 Limit: \(limit)")
            
            AF.request(url, method: .get, parameters: parameters)
                .validate()
                .responseJSON { response in
                    print("📊 Token Response Status: \(response.response?.statusCode ?? 0)")
                    
                    switch response.result {
                    case .success(let json):
                        if let dict = json as? [String: Any],
                           let status = dict["status"] as? String {
                            if status == "1",
                               let result = dict["result"] as? [[String: Any]] {
                                let transactions = result.compactMap {
                                    self.convertTokenTransaction($0, ownerAddress: address)
                                }
                                observer.onNext(transactions)
                                observer.onCompleted()
                            } else {
                                observer.onNext([])
                                observer.onCompleted()
                            }
                        } else {
                            observer.onNext([])
                            observer.onCompleted()
                        }
                    case .failure(let error):
                        print("❌ Token History Error: \(error.localizedDescription)")
                        observer.onNext([])
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
    
    private func convertToTransaction(_ dict: [String: Any], ownerAddress: String) -> Transaction? {
        guard let hash = dict["hash"] as? String,
              let from = dict["from"] as? String,
              let to = dict["to"] as? String,
              let value = dict["value"] as? String,
              let timestamp = dict["timeStamp"] as? String,
              let gasUsed = dict["gasUsed"] as? String,
              let isError = dict["isError"] as? String else {
            return nil
        }
        
        let amount = Decimal(string: value) ?? 0
        if amount == 0 {
            if let functionName = dict["functionName"] as? String,
               functionName.lowercased().contains("transfer") {
                return nil
            }
            if let input = dict["input"] as? String,
               input.hasPrefix("0xa9059cbb") {
                return nil
            }
        }
        let ethAmount = amount / Decimal(1_000_000_000_000_000_000)
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) ?? 0)
        let status: TransactionStatus = isError == "0" ? .success : .failed
        
        return Transaction(
            hash: hash,
            from: from,
            to: to,
            amount: ethAmount,
            currency: Currency.eth,
            gasUsed: Decimal(string: gasUsed) ?? 0,
            gasPrice: nil,
            status: status,
            direction: from.lowercased() == ownerAddress.lowercased() ? .outbound : .inbound,
            timestamp: date,
            blockNumber: nil,
            network: Network.sepolia
        )
    }
    
    private func convertTokenTransaction(_ dict: [String: Any], ownerAddress: String) -> Transaction? {
        guard let hash = dict["hash"] as? String,
              let from = dict["from"] as? String,
              let to = dict["to"] as? String,
              let value = dict["value"] as? String,
              let timestampString = dict["timeStamp"] as? String,
              let contractAddress = dict["contractAddress"] as? String,
              let tokenDecimalString = dict["tokenDecimal"] as? String ?? dict["tokenDecimals"] as? String,
              let tokenSymbol = dict["tokenSymbol"] as? String,
              let decimals = Int(tokenDecimalString),
              let rawAmount = Decimal(string: value) else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampString) ?? 0)
        let direction: TransactionDirection = from.lowercased() == ownerAddress.lowercased() ? .outbound : .inbound
        let amount = rawAmount / pow10(decimals)
        let currency = resolveCurrency(symbol: tokenSymbol, decimals: decimals, contractAddress: contractAddress)
        let status = resolveStatus(dict: dict)
        
        return Transaction(
            hash: hash,
            from: from,
            to: to,
            amount: amount,
            currency: currency,
            gasUsed: Decimal(string: dict["gasUsed"] as? String ?? ""),
            gasPrice: Decimal(string: dict["gasPrice"] as? String ?? ""),
            status: status,
            direction: direction,
            timestamp: timestamp,
            blockNumber: Int(dict["blockNumber"] as? String ?? ""),
            network: Network.sepolia
        )
    }
    
    private func pow10(_ exponent: Int) -> Decimal {
        NSDecimalNumber(mantissa: 1, exponent: Int16(exponent), isNegative: false).decimalValue
    }
    
    private func resolveCurrency(symbol: String, decimals: Int, contractAddress: String) -> Currency {
        let normalizedContract = contractAddress.lowercased()
        if let matched = Currency.supportedCurrencies.first(where: { currency in
            if let addr = currency.contractAddress?.lowercased() {
                return addr == normalizedContract
            }
            return currency.symbol.caseInsensitiveCompare(symbol) == .orderedSame
        }) {
            return matched
        }
        
        return Currency(
            symbol: symbol.uppercased(),
            name: symbol.uppercased(),
            decimals: decimals,
            contractAddress: contractAddress
        )
    }
    
    private func resolveStatus(dict: [String: Any]) -> TransactionStatus {
        if let isError = dict["isError"] as? String {
            return isError == "0" ? .success : .failed
        }
        if let receipt = dict["txreceipt_status"] as? String {
            return receipt == "1" ? .success : .failed
        }
        return .success
    }
}
