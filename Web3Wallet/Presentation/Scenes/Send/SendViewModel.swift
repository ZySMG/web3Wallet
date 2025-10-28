//
//  SendViewModel.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SendViewModel {
    
    struct Input {
        let toAddress = BehaviorRelay<String>(value: "")
        let amount = BehaviorRelay<String>(value: "")
        let sendTrigger = PublishRelay<Void>()
    }
    
    struct Output {
        let isSendEnabled: Driver<Bool>
        let gasPrice: Driver<String>
        let gasLimit: Driver<String>
        let fee: Driver<String>
        let totalCost: Driver<String>
        let balance: Driver<String>
        let addressValidation: Driver<String>
        let insufficientBalanceMessage: Driver<String>
        let error: Driver<Error>
    }
    
    let input = Input()
    let output: Output
    
    let estimateGasUseCase: EstimateGasUseCaseProtocol
    let ethereumService: EthereumServiceProtocol
    let sendTransactionUseCase: SendTransactionUseCaseProtocol
    private let balanceSubject: BehaviorRelay<String>
    let selectedCurrency: Currency
    
    // ✅ Added: Store current balance value and gas estimate
    private let currentBalanceSubject = BehaviorRelay<Decimal>(value: 0)
    let currentGasEstimateSubject = BehaviorRelay<GasEstimate?>(value: nil)
    var wallet: Wallet
    let disposeBag = DisposeBag()
    
    // ✅ Added: Store UI-related Subjects
    let gasPriceSubject: BehaviorRelay<String>
    let gasLimitSubject: BehaviorRelay<String>
    let feeSubject: BehaviorRelay<String>
    let totalCostSubject: BehaviorRelay<String>
    let addressValidationSubject: BehaviorRelay<String>
    let insufficientBalanceSubject: BehaviorRelay<String>
    let errorSubject: PublishRelay<Error>
    let gasCountdownTriggerSubject: PublishRelay<Void> 
    
    init(wallet: Wallet, estimateGasUseCase: EstimateGasUseCaseProtocol, ethereumService: EthereumServiceProtocol, sendTransactionUseCase: SendTransactionUseCaseProtocol, selectedCurrency: Currency = Currency.eth) {
        self.wallet = wallet
        self.estimateGasUseCase = estimateGasUseCase
        self.ethereumService = ethereumService
        self.sendTransactionUseCase = sendTransactionUseCase
        self.selectedCurrency = selectedCurrency
        
        let isSendEnabledSubject = BehaviorRelay<Bool>(value: false)
        let gasPriceSubject = BehaviorRelay<String>(value: "Gas Price: --")
        let gasLimitSubject = BehaviorRelay<String>(value: "Gas Limit: --")
        let feeSubject = BehaviorRelay<String>(value: "Network Fee: --")
        let totalCostSubject = BehaviorRelay<String>(value: "Total Cost: --")
        let balanceSubject = BehaviorRelay<String>(value: "Balance: 0.000000 \(selectedCurrency.symbol)")
        let addressValidationSubject = BehaviorRelay<String>(value: "")
        let insufficientBalanceSubject = BehaviorRelay<String>(value: "")
        let errorSubject = PublishRelay<Error>()
        let gasCountdownTriggerSubject = PublishRelay<Void>()
        
        // Store subjects for direct access
        self.balanceSubject = balanceSubject
        self.gasPriceSubject = gasPriceSubject
        self.gasLimitSubject = gasLimitSubject
        self.feeSubject = feeSubject
        self.totalCostSubject = totalCostSubject
        self.addressValidationSubject = addressValidationSubject
        self.insufficientBalanceSubject = insufficientBalanceSubject
        self.errorSubject = errorSubject
        self.gasCountdownTriggerSubject = gasCountdownTriggerSubject
        
        self.output = Output(
            isSendEnabled: isSendEnabledSubject.asDriver(),
            gasPrice: gasPriceSubject.asDriver(),
            gasLimit: gasLimitSubject.asDriver(),
            fee: feeSubject.asDriver(),
            totalCost: totalCostSubject.asDriver(),
            balance: balanceSubject.asDriver(),
            addressValidation: addressValidationSubject.asDriver(),
            insufficientBalanceMessage: insufficientBalanceSubject.asDriver(),
            error: errorSubject.asDriver(onErrorJustReturn: WalletError.walletNotFound)
        )
        
        // Load wallet balance
        loadWalletBalance()
        
        // Address validation
        input.toAddress
            .map { address in
                if address.isEmpty {
                    return ""
                } else if address.isValidEthereumAddressFormat {
                    return "✓ Valid address"
                } else {
                    return "✗ Invalid address format"
                }
            }
            .bind(to: addressValidationSubject)
            .disposed(by: disposeBag)
        
        // Form validation - simplified logic like before ViewModel split
        Observable.combineLatest(
            input.toAddress.map { $0.isValidEthereumAddressFormat },
            input.amount.map { !$0.isEmpty && Double($0) != nil },
            currentBalanceSubject.asObservable()
        )
        .map { isValidAddress, isValidAmount, balance in
            // Simple validation: valid address + valid amount + positive balance
            return isValidAddress && isValidAmount && balance > 0
        }
        .bind(to: isSendEnabledSubject)
        .disposed(by: disposeBag)
        
        // Gas estimation - simplified logic
        Observable.combineLatest(
            input.toAddress.asObservable(),
            input.amount.asObservable()
        )
        .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
        .filter { address, amount in
            return address.isValidEthereumAddressFormat && !amount.isEmpty
        }
        .flatMap { [weak self] address, amount -> Observable<GasEstimate> in
            guard let self = self,
                  let amountDecimal = Decimal(string: amount) else {
                return Observable.empty()
            }
            
            return self.estimateGasUseCase.estimateGas(
                from: self.wallet.address,
                to: address,
                amount: amountDecimal,
                currency: self.selectedCurrency,
                network: self.wallet.network
            )
            .map { gasLimit in
                // Create GasEstimate with default gas price
                let gasPrice = Decimal(20) // 20 Gwei
                let feeInETH = gasLimit * gasPrice / Decimal(1_000_000_000)
                
                return GasEstimate(
                    gasLimit: gasLimit,
                    gasPrice: gasPrice,
                    feeInETH: feeInETH
                )
            }
            .catch { _ in
                // Return default gas estimate on error
                return Observable.just(GasEstimate(
                    gasLimit: Decimal(21000),
                    gasPrice: Decimal(20),
                    feeInETH: Decimal(21000) * Decimal(20) / Decimal(1_000_000_000)
                ))
            }
        }
        .subscribe(onNext: { [weak self] gasEstimate in
            guard let self = self else { return }
            
            // Update gas estimate
            self.currentGasEstimateSubject.accept(gasEstimate)
            
            // Update UI labels
            self.gasPriceSubject.accept("Gas Price: \(gasEstimate.formattedGasPrice)")
            self.gasLimitSubject.accept("Gas Limit: \(gasEstimate.gasLimit)")
            self.feeSubject.accept("Network Fee: \(gasEstimate.formattedFee)")
            
            // Calculate total cost
            if let amount = Decimal(string: self.input.amount.value) {
                let totalCost = amount + gasEstimate.feeInETH
                self.totalCostSubject.accept("Total Cost: \(totalCost.rounded(toPlaces: 6)) \(self.selectedCurrency.symbol)")
            }
            
            // Trigger gas countdown
            self.gasCountdownTriggerSubject.accept(())
        })
        .disposed(by: disposeBag)
        
        // Insufficient balance message
        Observable.combineLatest(
            input.amount.asObservable(),
            currentBalanceSubject.asObservable(),
            currentGasEstimateSubject.asObservable()
        )
        .map { [weak self] amountString, balance, gasEstimate in
            guard let self = self,
                  let amount = Decimal(string: amountString),
                  let gasEstimate = gasEstimate else {
                return ""
            }
            
            let totalCost = amount + gasEstimate.feeInETH
            
            if balance < totalCost {
                return "Insufficient balance. Need \(totalCost.rounded(toPlaces: 6)) \(self.selectedCurrency.symbol), have \(balance.rounded(toPlaces: 6)) \(self.selectedCurrency.symbol)"
            } else {
                return ""
            }
        }
        .bind(to: insufficientBalanceSubject)
        .disposed(by: disposeBag)
    }
    
    private func loadWalletBalance() {
        let appContainer = AppContainer()
        let ethereumService = appContainer.ethereumService
        
        ethereumService.getBalance(address: wallet.address, currency: selectedCurrency, network: wallet.network)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] balance in
                    guard let self = self else { return }
                    
                    self.currentBalanceSubject.accept(balance)
                    self.balanceSubject.accept("Balance: \(balance.rounded(toPlaces: 6)) \(self.selectedCurrency.symbol)")
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    print("Failed to load balance: \(error)")
                    self.balanceSubject.accept("Balance: 0.000000 \(self.selectedCurrency.symbol)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    // ✅ Added: Method to update wallet
    func updateWallet(_ newWallet: Wallet) {
        self.wallet = newWallet
        loadWalletBalance()
        
        // Clear input fields
        input.toAddress.accept("")
        input.amount.accept("")
        
        // Reset gas estimation UI
        gasPriceSubject.accept("Gas Price: --")
        gasLimitSubject.accept("Gas Limit: --")
        feeSubject.accept("Network Fee: --")
        totalCostSubject.accept("Total Cost: --")
        currentGasEstimateSubject.accept(nil)
    }
}
