//
//  TransactionHistoryViewModel.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// Transaction history input
struct TransactionHistoryInput {
    let refreshTrigger = PublishRelay<Void>()
    let transactionSelected = PublishRelay<Transaction>()
}

/// Transaction history output
struct TransactionHistoryOutput {
    let transactions: Driver<[Transaction]>
    let isLoading: Driver<Bool>
    let error: Driver<Error>
    let showTransactionDetail: Driver<Transaction>
}

/// Transaction history view model
class TransactionHistoryViewModel {
    
    let input = TransactionHistoryInput()
    let output: TransactionHistoryOutput
    
    private let disposeBag = DisposeBag()
    private var wallet: Wallet
    private let fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol
    
    // Internal state
    private let transactionsSubject = BehaviorRelay<[Transaction]>(value: [])
    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
    private let errorSubject = PublishRelay<Error>()
    
    init(wallet: Wallet, fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol) {
        self.wallet = wallet
        self.fetchTxHistoryUseCase = fetchTxHistoryUseCase
        
        // Create output
        self.output = TransactionHistoryOutput(
            transactions: transactionsSubject.asDriver(),
            isLoading: isLoadingSubject.asDriver(),
            error: errorSubject.asDriver(onErrorJustReturn: WalletError.walletNotFound),
            showTransactionDetail: input.transactionSelected.asDriver(onErrorJustReturn: Transaction(
                hash: "",
                from: "",
                to: "",
                amount: 0,
                currency: Currency.eth,
                status: .success,
                direction: .outbound,
                timestamp: Date(),
                network: wallet.network
            ))
        )
        
        setupBindings()
        loadInitialData()
    }
    
    private func setupBindings() {
        // Refresh trigger
        input.refreshTrigger
            .subscribe(onNext: { [weak self] in
                self?.refreshData()
            })
            .disposed(by: disposeBag)
    }
    
    private func loadInitialData() {
        refreshData()
    }
    
    private func refreshData() {
        isLoadingSubject.accept(true)
        
        // Get transaction history
        fetchTxHistoryUseCase.fetchTransactionHistory(for: wallet, limit: 50)
            .subscribe(onNext: { [weak self] transactions in
                self?.transactionsSubject.accept(transactions)
                self?.isLoadingSubject.accept(false)
            }, onError: { [weak self] error in
                self?.errorSubject.accept(error)
                self?.isLoadingSubject.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Wallet Update
    
    func updateWallet(_ newWallet: Wallet) {
        // ✅ Update wallet
        self.wallet = newWallet
        
        // ✅ Clear current transaction list
        transactionsSubject.accept([])
        
        // ✅ Reload transaction history
        refreshData()
        
        print("🔄 TransactionHistoryViewModel updated for wallet: \(newWallet.address)")
    }
}
