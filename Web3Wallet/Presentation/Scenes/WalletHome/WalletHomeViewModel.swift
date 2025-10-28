//
//  WalletHomeViewModel.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// 钱包首页输入
struct WalletHomeInput {
    let refreshTrigger = PublishRelay<Void>()
    let receiveTrigger = PublishRelay<Void>()
    let sendTrigger = PublishRelay<Void>()
    let transactionTrigger = PublishRelay<Void>()
    let networkSwitchTrigger = PublishRelay<Void>()
    let walletManagementTrigger = PublishRelay<Void>()
    let transactionSelected = PublishRelay<Transaction>()
}

/// 钱包首页输出
struct WalletHomeOutput {
    let totalBalance: Driver<String>
    let balances: Driver<[Balance]>
    let transactions: Driver<[Transaction]>
    let isLoading: Driver<Bool>
    let error: Driver<Error>
    let showReceive: Driver<Wallet>
    let showSend: Driver<Wallet>
    let showTransaction: Driver<Transaction>
    let showTransactionHistory: Driver<Wallet>
    let showNetworkSelection: Driver<Void>
    let showWalletManagement: Driver<Void>
    let currentNetwork: Driver<String>
    let accountName: Driver<String>
}

/// 钱包首页视图模型
class WalletHomeViewModel {
    
    let input = WalletHomeInput()
    let output: WalletHomeOutput
    
    private let disposeBag = DisposeBag()
    private var wallet: Wallet
    private let resolveBalancesUseCase: ResolveBalancesUseCaseProtocol
    private let fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol
    private let priceService: PriceServiceProtocol
    
    // Internal state
    private let totalBalanceSubject = BehaviorRelay<String>(value: "Total Assets: $0.00")
    private let balancesSubject = BehaviorRelay<[Balance]>(value: [])
    private let transactionsSubject = BehaviorRelay<[Transaction]>(value: [])
    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
    private let errorSubject = PublishRelay<Error>()
    private let currentNetworkSubject = BehaviorRelay<String>(value: "Ethereum Sepolia")
    private let accountNameSubject = BehaviorRelay<String>(value: "Account 1")
    private var currentNetwork: Network = .sepolia
    
    init(wallet: Wallet,
         resolveBalancesUseCase: ResolveBalancesUseCaseProtocol,
         fetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol,
         priceService: PriceServiceProtocol) {
        
        self.wallet = wallet
        self.resolveBalancesUseCase = resolveBalancesUseCase
        self.fetchTxHistoryUseCase = fetchTxHistoryUseCase
        self.priceService = priceService
        
        // 创建输出
        self.output = WalletHomeOutput(
            totalBalance: totalBalanceSubject.asDriver(),
            balances: balancesSubject.asDriver(),
            transactions: transactionsSubject.asDriver(),
            isLoading: isLoadingSubject.asDriver(),
            error: errorSubject.asDriver(onErrorJustReturn: WalletError.walletNotFound),
            showReceive: input.receiveTrigger.map { wallet }.asDriver(onErrorJustReturn: wallet),
            showSend: input.sendTrigger.map { wallet }.asDriver(onErrorJustReturn: wallet),
            showTransaction: input.transactionSelected.asDriver(onErrorJustReturn: Transaction(
                hash: "",
                from: "",
                to: "",
                amount: 0,
                currency: Currency.eth,
                status: .success,
                direction: .outbound,
                timestamp: Date(),
                network: wallet.network
            )),
            showTransactionHistory: input.transactionTrigger.map { wallet }.asDriver(onErrorJustReturn: wallet),
            showNetworkSelection: input.networkSwitchTrigger.asDriver(onErrorJustReturn: ()),
            showWalletManagement: input.walletManagementTrigger.asDriver(onErrorJustReturn: ()),
            currentNetwork: currentNetworkSubject.asDriver(),
            accountName: accountNameSubject.asDriver()
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
        
        // 前台唤醒刷新
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .map { _ in () }
            .bind(to: input.refreshTrigger)
            .disposed(by: disposeBag)
    }
    
    private func loadInitialData() {
        refreshData()
    }
    
    private func refreshData() {
        isLoadingSubject.accept(true)
        
        // 创建当前网络的钱包实例
        let currentWallet = Wallet(
            address: wallet.address,
            network: currentNetwork,
            isImported: wallet.isImported
        )
        
        // 获取余额 - 添加延迟避免API频率限制
        resolveBalancesUseCase.resolveBalances(for: currentWallet, currencies: Currency.supportedCurrencies)
            .delay(.milliseconds(200), scheduler: MainScheduler.instance) // 200ms延迟
            .subscribe(onNext: { [weak self] balances in
                self?.balancesSubject.accept(balances)
                self?.isLoadingSubject.accept(false)
                // self?.updateTotalBalance(balances) // 暂时不直接更新，等待价格数据
            }, onError: { [weak self] error in
                self?.isLoadingSubject.accept(false)
                
                // Provide default balances for all currencies when network fails
                let defaultBalances = [
                    Balance(
                        currency: Currency.eth,
                        amount: Decimal(0),
                        usdValue: Decimal(0),
                        lastUpdated: Date()
                    ),
                    Balance(
                        currency: Currency.usdc,
                        amount: Decimal(0),
                        usdValue: Decimal(0),
                        lastUpdated: Date()
                    ),
                    Balance(
                        currency: Currency.usdt,
                        amount: Decimal(0),
                        usdValue: Decimal(0),
                        lastUpdated: Date()
                    )
                ]
                self?.balancesSubject.accept(defaultBalances)
                
                // Only show error for critical issues, not for zero balance
                print("Balance fetch error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        
        // 获取交易历史 - 添加延迟避免API频率限制
        fetchTxHistoryUseCase.fetchTransactionHistory(for: currentWallet, limit: 10)
            .delay(.milliseconds(400), scheduler: MainScheduler.instance) // 400ms延迟
            .subscribe(onNext: { [weak self] transactions in
                self?.transactionsSubject.accept(transactions)
            }, onError: { [weak self] error in
                // Show specific error information
                if let nsError = error as NSError? {
                    if nsError.domain == "NSURLErrorDomain" && nsError.code == -1003 {
                        self?.errorSubject.accept(WalletError.networkError("Network connection failed. Please check your internet connection."))
                    } else if nsError.domain == "NSURLErrorDomain" && nsError.code == -1001 {
                        self?.errorSubject.accept(WalletError.networkError("Request timeout. The server may be slow or unreachable."))
                    } else if nsError.code == 429 {
                        self?.errorSubject.accept(WalletError.networkError("API rate limit exceeded. Please wait a moment and try again."))
                    } else {
                        self?.errorSubject.accept(WalletError.networkError("Network error: \(nsError.localizedDescription)"))
                    }
                } else {
                    self?.errorSubject.accept(error)
                }
                print("Transaction history fetch error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        
        // 获取价格 - 添加延迟避免API频率限制
        priceService.getTokenPrices(currencies: Currency.supportedCurrencies)
            .delay(.milliseconds(600), scheduler: MainScheduler.instance) // 600ms延迟
            .subscribe(onNext: { [weak self] prices in
                self?.updateBalancesWithPrices(prices: prices)
            }, onError: { [weak self] error in
                // Show specific error information
                if let nsError = error as NSError? {
                    if nsError.domain == "NSURLErrorDomain" && nsError.code == -1003 {
                        self?.errorSubject.accept(WalletError.networkError("Network connection failed. Please check your internet connection."))
                    } else if nsError.domain == "NSURLErrorDomain" && nsError.code == -1001 {
                        self?.errorSubject.accept(WalletError.networkError("Request timeout. The server may be slow or unreachable."))
                    } else if nsError.code == 429 {
                        self?.errorSubject.accept(WalletError.networkError("API rate limit exceeded. Please wait a moment and try again."))
                    } else {
                        self?.errorSubject.accept(WalletError.networkError("Network error: \(nsError.localizedDescription)"))
                    }
                } else {
                    self?.errorSubject.accept(error)
                }
                print("Price fetch error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        
        // 完成加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoadingSubject.accept(false)
        }
    }
    
    private func updateTotalBalance(_ balances: [Balance]) {
        // Calculate total USD value
        let totalUSD = balances.reduce(0) { $0 + ($1.usdValue ?? 0) }
        
        totalBalanceSubject.accept("Total Assets: $\(totalUSD.formatted(decimals: 2))")
    }
    
                    private func updateBalancesWithPrices(prices: [String: Decimal]) {
                        let currentBalances = balancesSubject.value
                        let updatedBalances = currentBalances.map { balance in
                            let price = prices[balance.currency.symbol] ?? 0
                            let usdValue = balance.amount * price
                            return Balance(
                                currency: balance.currency,
                                amount: balance.amount,
                                usdValue: usdValue,
                                lastUpdated: Date()
                            )
                        }
                        
                        // 过滤余额：ETH、USDC、USDT始终显示（包括0余额），其他代币只显示非零余额
                        let filteredBalances = updatedBalances.filter { balance in
                            let alwaysShowSymbols = ["ETH", "USDC", "USDT"]
                            if alwaysShowSymbols.contains(balance.currency.symbol) {
                                return true // ETH、USDC、USDT始终显示，包括0余额
                            }
                            return balance.amount > 0 // 其他代币只显示非零余额
                        }
                        
                        balancesSubject.accept(filteredBalances)
                        updateTotalBalance(filteredBalances)
                    }
    
    // MARK: - Public Methods
    
    func switchNetwork(to network: Network) {
        currentNetwork = network
        currentNetworkSubject.accept(network.name)
        
        // 切换网络后重新加载数据
        refreshData()
    }
    
    func getCurrentNetwork() -> Network {
        return currentNetwork
    }
    
    func switchToWallet(_ wallet: Wallet) {
        // 更新当前钱包
        self.wallet = wallet
        currentNetwork = wallet.network
        currentNetworkSubject.accept(wallet.network.name)
        
        // 重新加载数据
        refreshData()
    }
}
