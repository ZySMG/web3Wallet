//
//  SendTransactionUseCase.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//

import Foundation
import RxSwift
import WalletCore
import WalletCoreSwiftProtobuf

// 你工程里已有的协议/类型：EthereumServiceProtocol / Wallet / Currency / GasEstimate / WalletError
// 本文件负责：派生私钥 -> 获取 nonce / gasPrice -> 构造并签名 -> 广播 -> 返回 txHash

protocol SendTransactionUseCaseProtocol {
    func sendTransaction(
        from wallet: Wallet,
        to address: String,
        amount: Decimal,
        currency: Currency,
        gasEstimate: GasEstimate,
        mnemonic: String
    ) -> Observable<String>
}

final class SendTransactionUseCase: SendTransactionUseCaseProtocol {
    private let ethereumService: EthereumServiceProtocol

    init(ethereumService: EthereumServiceProtocol) {
        self.ethereumService = ethereumService
    }

    /// 发送交易（原生 ETH / ERC-20）
    /// - Parameters:
    ///   - wallet: 包含 sender address & network
    ///   - address: 收款地址
    ///   - amount: 转账数量（Decimal）
    ///   - currency: 当前选择的币（ETH / USDC / USDT(Test)）
    ///   - gasEstimate: 估算得到的 gasLimit（以及你需要的其它字段）
    ///   - mnemonic: 助记词（只在本地用于签名）
    /// - Returns: 上链后返回 txHash（String）
    func sendTransaction(
        from wallet: Wallet,
        to address: String,
        amount: Decimal,
        currency: Currency,
        gasEstimate: GasEstimate,
        mnemonic: String
    ) -> Observable<String> {

        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WalletError.unknown)
                return Disposables.create()
            }

            // 1) 从助记词派生私钥（使用钱包的派生路径）
            guard let hd = HDWallet(mnemonic: mnemonic, passphrase: "") else {
                observer.onError(WalletError.invalidMnemonic)
                return Disposables.create()
            }
            let privateKey = hd.getKey(coin: .ethereum, derivationPath: "m/44'/60'/0'/0/0")
            
            // ✅ 添加调试日志
            print("🔑 SendTransactionUseCase: Wallet address: \(wallet.address)")
            print("🔑 SendTransactionUseCase: Derivation path: m/44'/60'/0'/0/0")
            print("🔑 SendTransactionUseCase: Private key derived successfully")

            // 2) 获取 nonce(pending) + gasPrice(Gwei)
            let innerDisposable =
                Observable.zip(
                    self.ethereumService.getNonce(address: wallet.address, network: wallet.network),
                    self.ethereumService.getGasPrice(network: wallet.network) // Gwei
                )
                .flatMap { [weak self] (nonce, gasPriceGwei) -> Observable<String> in
                    guard let self = self else { return Observable.error(WalletError.unknown) }

                    // 3) 构造并签名 rawTx（ETH / ERC-20 均支持）
                    guard let rawTx = self.buildTransaction(
                        from: wallet.address,
                        to: address,
                        amount: amount,
                        currency: currency,
                        nonce: nonce,
                        gasPriceGwei: gasPriceGwei,          // Gwei
                        gasLimit: gasEstimate.gasLimit,       // Decimal
                        chainId: wallet.network.chainId,      // Int
                        privateKey: privateKey
                    ) else {
                        return Observable.error(WalletError.transactionCreationFailed)
                    }

                    // 4) 广播
                    return self.ethereumService.sendRawTransaction(rawTransaction: rawTx, network: wallet.network)
                }
                .subscribe(onNext: { txHash in
                    observer.onNext(txHash)
                    observer.onCompleted()
                }, onError: { error in
                    observer.onError(error)
                })

            return Disposables.create {
                innerDisposable.dispose()
            }
        }
    }

    // MARK: - Build & Sign

    /// 使用 TrustWalletCore 构造并签名交易，返回 raw tx (0x...)
    private func buildTransaction(
        from: String,
        to: String,
        amount: Decimal,
        currency: Currency,
        nonce: Int,
        gasPriceGwei: Decimal,
        gasLimit: Decimal,
        chainId: Int,
        privateKey: PrivateKey
    ) -> String? {

        // 单位换算辅助
        func toUnits(_ value: Decimal, decimals: Int) -> UInt64? {
            let scale = pow(10 as Decimal, decimals)
            let scaled = NSDecimalNumber(decimal: value).multiplying(by: NSDecimalNumber(decimal: scale)).decimalValue
            let rounded = NSDecimalNumber(decimal: scaled).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
            return UInt64(exactly: rounded)
        }

        // Gwei -> Wei (1e9)
        let gasPriceWeiDecimal = NSDecimalNumber(decimal: gasPriceGwei).multiplying(by: NSDecimalNumber(value: 1_000_000_000)).decimalValue
        let gasPriceWeiRounded = NSDecimalNumber(decimal: gasPriceWeiDecimal).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
        guard
            let gasPriceWei = UInt64(exactly: gasPriceWeiRounded),
            let gasLimitU64 = UInt64(exactly: NSDecimalNumber(decimal: gasLimit))
        else {
            return nil
        }

        // 填充工具
        func hex(_ v: UInt64) -> String { String(v, radix: 16) }
        func evenPaddedHex(_ s: String) -> String { s.count % 2 == 0 ? s : ("0" + s) }
        func hexData(_ v: UInt64) -> Data { Data(hexString: evenPaddedHex(String(v, radix: 16))) ?? Data() }
        func hexDataInt(_ v: Int) -> Data { Data(hexString: evenPaddedHex(String(v, radix: 16))) ?? Data() }
        func hexDataFromDec(_ d: Decimal) -> Data {
            guard let u = UInt64(exactly: NSDecimalNumber(decimal: d)) else { return Data() }
            return Data(hexString: evenPaddedHex(String(u, radix: 16))) ?? Data()
        }

        var input = EthereumSigningInput()
        input.privateKey = privateKey.data
        input.chainID     = hexDataInt(chainId)
        input.nonce       = hexDataInt(nonce)
        input.gasLimit    = hexData(gasLimitU64)
        input.gasPrice    = hexData(gasPriceWei)              // 使用 legacy gasPrice（足够测试；未来可切 EIP-1559）

        var tx = EthereumTransaction()

        if let contract = currency.contractAddress, !contract.isEmpty {
            // === ERC-20 代币转账 ===
            input.toAddress = contract

            var erc20 = EthereumTransaction.ERC20Transfer()
            erc20.to = to
            guard let tokenUnits = toUnits(amount, decimals: currency.decimals) else { return nil }
            let tokenHex = evenPaddedHex(hex(tokenUnits))
            erc20.amount = Data(hexString: tokenHex) ?? Data()
            tx.erc20Transfer = erc20
        } else {
            // === 原生 ETH 转账 ===
            input.toAddress = to
            guard let amountWei = toUnits(amount, decimals: 18) else { return nil }
            var transfer = EthereumTransaction.Transfer()
            transfer.amount = Data(hexString: evenPaddedHex(hex(amountWei))) ?? Data()
            tx.transfer = transfer
        }

        input.transaction = tx

        // 签名
        let output: EthereumSigningOutput = AnySigner.sign(input: input, coin: .ethereum)
        let raw = "0x" + output.encoded.hexString
        return raw
    }
}
