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

/// 交易历史输入
struct TransactionHistoryInput {
    let refreshTrigger = PublishRelay<Void>()
    let transactionSelected = PublishRelay<Transaction>()
}

/// 交易历史输出
struct TransactionHistoryOutput {
    let transactions: Driver<[Transaction]>
    let isLoading: Driver<Bool>
    let error: Driver<Error>
    let showTransactionDetail: Driver<Transaction>
}

/// 交易历史视图模型
class TransactionHistoryViewModel {
    
    let input = TransactionHistoryInput()
    let output: TransactionHistoryOutput
    
    private let disposeBag = DisposeBag()
    private var wallet: Wallet
    private let fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol
    
    // 内部状态
    private let transactionsSubject = BehaviorRelay<[Transaction]>(value: [])
    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
    private let errorSubject = PublishRelay<Error>()
    
    init(wallet: Wallet, fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol) {
        self.wallet = wallet
        self.fetchTxHistoryUseCase = fetchTxHistoryUseCase
        
        // 创建输出
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
        // 刷新触发
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
        
        // 获取交易历史
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
        // ✅ 更新钱包
        self.wallet = newWallet
        
        // ✅ 清空当前交易列表
        transactionsSubject.accept([])
        
        // ✅ 重新加载交易历史
        refreshData()
        
        print("🔄 TransactionHistoryViewModel updated for wallet: \(newWallet.address)")
    }
}
