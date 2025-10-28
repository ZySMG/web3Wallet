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

// Your existing protocols/types: EthereumServiceProtocol / Wallet / Currency / GasEstimate / WalletError
// This file is responsible for: derive private key -> get nonce / gasPrice -> construct and sign -> broadcast -> return txHash

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

    /// Send transaction (native ETH / ERC-20)
    /// - Parameters:
    ///   - wallet: Contains sender address & network
    ///   - address: Recipient address
    ///   - amount: Transfer amount (Decimal)
    ///   - currency: Currently selected currency (ETH / USDC / USDT(Test))
    ///   - gasEstimate: Estimated gasLimit (and other fields you need)
    ///   - mnemonic: Mnemonic phrase (only used locally for signing)
    /// - Returns: Returns txHash (String) after being on-chain
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

            // 1) Derive private key from mnemonic (using wallet's derivation path)
            guard let hd = HDWallet(mnemonic: mnemonic, passphrase: "") else {
                observer.onError(WalletError.invalidMnemonic)
                return Disposables.create()
            }
            let privateKey = hd.getKey(coin: .ethereum, derivationPath: "m/44'/60'/0'/0/0")
            
            // ✅ Add debug logging
            print("🔑 SendTransactionUseCase: Wallet address: \(wallet.address)")
            print("🔑 SendTransactionUseCase: Derivation path: m/44'/60'/0'/0/0")
            print("🔑 SendTransactionUseCase: Private key derived successfully")

            // 2) Get nonce(pending) + gasPrice(Gwei)
            let innerDisposable =
                Observable.zip(
                    self.ethereumService.getNonce(address: wallet.address, network: wallet.network),
                    self.ethereumService.getGasPrice(network: wallet.network) // Gwei
                )
                .flatMap { [weak self] (nonce, gasPriceGwei) -> Observable<String> in
                    guard let self = self else { return Observable.error(WalletError.unknown) }

                    // 3) Construct and sign rawTx (supports both ETH / ERC-20)
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

                    // 4) Broadcast
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

    /// Use TrustWalletCore to construct and sign transaction, return raw tx (0x...)
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

        // Unit conversion helper
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

        // Padding helper
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
        input.gasPrice    = hexData(gasPriceWei)              // Use legacy gasPrice (sufficient for testing; can switch to EIP-1559 in future)

        var tx = EthereumTransaction()

        if let contract = currency.contractAddress, !contract.isEmpty {
            // === ERC-20 token transfer ===
            input.toAddress = contract

            var erc20 = EthereumTransaction.ERC20Transfer()
            erc20.to = to
            guard let tokenUnits = toUnits(amount, decimals: currency.decimals) else { return nil }
            let tokenHex = evenPaddedHex(hex(tokenUnits))
            erc20.amount = Data(hexString: tokenHex) ?? Data()
            tx.erc20Transfer = erc20
        } else {
            // === Native ETH transfer ===
            input.toAddress = to
            guard let amountWei = toUnits(amount, decimals: 18) else { return nil }
            var transfer = EthereumTransaction.Transfer()
            transfer.amount = Data(hexString: evenPaddedHex(hex(amountWei))) ?? Data()
            tx.transfer = transfer
        }

        input.transaction = tx

        // Sign
        let output: EthereumSigningOutput = AnySigner.sign(input: input, coin: .ethereum)
        let raw = "0x" + output.encoded.hexString
        return raw
    }
}
