//
//  EthereumService.swift
//  Web3Wallet
//

import Foundation
import RxSwift
import Alamofire

// 你工程里已有的：Network / Currency / WalletError / EtherscanV2Service
// 本服务负责：nonce / gasPrice / sendRawTx（三个关键） + 余额（走 Etherscan V2）

protocol EthereumServiceProtocol {
    func getNonce(address: String, network: Network) -> Observable<Int>
    func getGasPrice(network: Network) -> Observable<Decimal>     // 返回 Gwei
    func sendRawTransaction(rawTransaction: String, network: Network) -> Observable<String>
    func getBalance(address: String, currency: Currency, network: Network) -> Observable<Decimal>
}

final class EthereumService: EthereumServiceProtocol {

    private let etherscan: EtherscanV2Service

    init(etherscan: EtherscanV2Service) {
        self.etherscan = etherscan
    }

    // MARK: - JSON-RPC 基础

    func getNonce(address: String, network: Network) -> Observable<Int> {
        return Observable.create { observer in
            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "eth_getTransactionCount",
                "params": [address, "pending"], // ✅ 使用 pending，避免 nonce too low
                "id": 1
            ]
            AF.request(network.rpcURL, method: .post, parameters: payload, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { resp in
                    switch resp.result {
                    case .success(let json):
                        guard
                            let dict = json as? [String: Any],
                            let result = dict["result"] as? String
                        else { observer.onError(WalletError.unknown); return }
                        let hex = result.lowercased().hasPrefix("0x") ? String(result.dropFirst(2)) : result
                        if let nonce = Int(hex, radix: 16) {
                            observer.onNext(nonce)
                            observer.onCompleted()
                        } else {
                            observer.onError(WalletError.unknown)
                        }
                    case .failure(let e):
                        print("❌ Network Error: \(e.localizedDescription)")
                        if let afError = e as? AFError, afError.responseCode == 429 {
                            observer.onError(WalletError.networkError("API请求过于频繁，请稍后再试"))
                        } else {
                            observer.onError(e)
                        }
                    }
                }
            return Disposables.create()
        }
    }

    /// 返回 **Gwei**（Decimal）
    func getGasPrice(network: Network) -> Observable<Decimal> {
        return Observable.create { observer in
            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "eth_gasPrice",
                "params": [],
                "id": 1
            ]
            AF.request(network.rpcURL, method: .post, parameters: payload, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { resp in
                    switch resp.result {
                    case .success(let json):
                        guard
                            let dict = json as? [String: Any],
                            let result = dict["result"] as? String
                        else { observer.onError(WalletError.unknown); return }
                        let hex = result.lowercased().hasPrefix("0x") ? String(result.dropFirst(2)) : result
                        if let wei = UInt64(hex, radix: 16) {
                            let gwei = Decimal(wei) / Decimal(1_000_000_000) // 1e9
                            observer.onNext(gwei)
                            observer.onCompleted()
                        } else {
                            observer.onError(WalletError.unknown)
                        }
                    case .failure(let e):
                        print("❌ Network Error: \(e.localizedDescription)")
                        if let afError = e as? AFError, afError.responseCode == 429 {
                            observer.onError(WalletError.networkError("API请求过于频繁，请稍后再试"))
                        } else {
                            observer.onError(e)
                        }
                    }
                }
            return Disposables.create()
        }
    }

    func sendRawTransaction(rawTransaction: String, network: Network) -> Observable<String> {
        return Observable.create { observer in
            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "eth_sendRawTransaction",
                "params": [rawTransaction],
                "id": 1
            ]
            AF.request(network.rpcURL, method: .post, parameters: payload, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { resp in
                    switch resp.result {
                    case .success(let json):
                        if
                            let dict = json as? [String: Any],
                            let error = dict["error"] as? [String: Any],
                            let message = error["message"] as? String
                        {
                            observer.onError(WalletError.networkError(message))
                            return
                        }
                        guard
                            let dict = json as? [String: Any],
                            let result = dict["result"] as? String
                        else {
                            observer.onError(WalletError.unknown)
                            return
                        }
                        observer.onNext(result) // txHash
                        observer.onCompleted()
                    case .failure(let e):
                        print("❌ Network Error: \(e.localizedDescription)")
                        if let afError = e as? AFError, afError.responseCode == 429 {
                            observer.onError(WalletError.networkError("API请求过于频繁，请稍后再试"))
                        } else {
                            observer.onError(e)
                        }
                    }
                }
            return Disposables.create()
        }
    }

    // MARK: - 余额（走 Etherscan V2，带 chainid）
    func getBalance(address: String, currency: Currency, network: Network) -> Observable<Decimal> {
        if let contract = currency.contractAddress, !contract.isEmpty {
            // token balance
            return etherscan.getTokenBalance(address: address, contractAddress: contract, chainId: network.chainId)
                .map { raw -> Decimal in
                    // raw 是最小单位整数字符串（例如 USDC 6 位）
                    let units = Decimal(string: raw) ?? 0
                    let scale = pow(10 as Decimal, currency.decimals)
                    let result = NSDecimalNumber(decimal: units).dividing(by: NSDecimalNumber(decimal: scale)).decimalValue
                    return result.rounded(scale: 6)
                }
        } else {
            // native balance
            return etherscan.getETHBalance(address: address, chainId: network.chainId)
                .map { raw -> Decimal in
                    // raw 是 Wei（字符串）
                    let wei = Decimal(string: raw) ?? 0
                    let divisor = Decimal(1_000_000_000_000_000_000)
                    let result = NSDecimalNumber(decimal: wei).dividing(by: NSDecimalNumber(decimal: divisor)).decimalValue
                    return result.rounded(scale: 6) // to ETH
                }
        }
    }
}

// 一点小工具：保留 6 位小数（显示友好）
private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var v = self
        var res = Decimal()
        NSDecimalRound(&res, &v, scale, .plain)
        return res
    }
}
