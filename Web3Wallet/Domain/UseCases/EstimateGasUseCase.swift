//
//  EstimateGasUseCase.swift
//  Web3Wallet
//

import Foundation
import RxSwift
import Alamofire

protocol EstimateGasUseCaseProtocol {
    func estimateGas(from: String, to: String, amount: Decimal, currency: Currency, network: Network) -> Observable<Decimal>
}

/// 使用 eth_estimateGas 估算（原生 & ERC-20）
final class EstimateGasUseCase: EstimateGasUseCaseProtocol {

    func estimateGas(from: String, to: String, amount: Decimal, currency: Currency, network: Network) -> Observable<Decimal> {
        return Observable.create { observer in
            // decimal -> 0x hex（简化为 UInt64，足以覆盖测试用额）
            func toUnitsHex(_ value: Decimal, decimals: Int) -> String {
                let scale = pow(10 as Decimal, decimals)
                let scaled = NSDecimalNumber(decimal: value).multiplying(by: NSDecimalNumber(decimal: scale)).decimalValue
                let rounded = NSDecimalNumber(decimal: scaled).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
                let n = rounded.uint64Value
                return "0x" + String(n, radix: 16)
            }

            var call: [String: Any] = [
                "from": from.lowercased()
            ]

            if let contract = currency.contractAddress, !contract.isEmpty {
                // ERC-20 transfer
                call["to"] = contract
                call["value"] = "0x0"
                // data = a9059cbb + to(32 bytes) + amount(32 bytes)
                let method = "a9059cbb"
                let toNo0x = to.lowercased().replacingOccurrences(of: "0x", with: "")
                let toPadded = String(repeating: "0", count: 64 - toNo0x.count) + toNo0x
                let amtNo0x = String(toUnitsHex(amount, decimals: currency.decimals).dropFirst(2))
                let amtPadded = String(repeating: "0", count: 64 - amtNo0x.count) + amtNo0x
                call["data"] = "0x" + method + toPadded + amtPadded
            } else {
                // Native ETH
                call["to"] = to
                call["value"] = toUnitsHex(amount, decimals: 18)
            }

            let payload: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "eth_estimateGas",
                "params": [call],
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
                        else { observer.onError(WalletError.unknown); return }

                        let hex = result.lowercased().hasPrefix("0x") ? String(result.dropFirst(2)) : result
                        if let gas = UInt64(hex, radix: 16) {
                            observer.onNext(Decimal(gas))
                            observer.onCompleted()
                        } else {
                            observer.onError(WalletError.unknown)
                        }
                    case .failure(let e):
                        observer.onError(e)
                    }
                }

            return Disposables.create()
        }
    }
}
