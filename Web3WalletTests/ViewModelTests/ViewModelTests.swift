//
//  ViewModelTests.swift
//  Web3WalletTests
//
//  Created by Web3Wallet on 2025/01/01.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import Web3Wallet

class ViewModelTests: XCTestCase {
    
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    override func tearDown() {
        disposeBag = nil
        scheduler = nil
        super.tearDown()
    }
    
    // MARK: - WalletHomeViewModel Tests
    
    func testWalletHomeViewModelInitialization() {
        let wallet = Wallet(
            address: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            network: Network.sepolia
        )
        
        let mockResolveBalancesUseCase = MockResolveBalancesUseCase()
        let mockFetchTxHistoryUseCase = MockFetchTxHistoryUseCase()
        let mockPriceService = MockPriceService()
        
        let viewModel = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: mockResolveBalancesUseCase,
            fetchTxHistoryUseCase: mockFetchTxHistoryUseCase,
            priceService: mockPriceService
        )
        
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.output.totalBalance.value, "0.00 ETH")
        XCTAssertEqual(viewModel.output.balances.value.count, 0)
        XCTAssertEqual(viewModel.output.transactions.value.count, 0)
    }
    
    func testWalletHomeViewModelRefresh() {
        let wallet = Wallet(
            address: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            network: Network.sepolia
        )
        
        let mockResolveBalancesUseCase = MockResolveBalancesUseCase()
        let mockFetchTxHistoryUseCase = MockFetchTxHistoryUseCase()
        let mockPriceService = MockPriceService()
        
        let viewModel = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: mockResolveBalancesUseCase,
            fetchTxHistoryUseCase: mockFetchTxHistoryUseCase,
            priceService: mockPriceService
        )
        
        let totalBalanceObserver = scheduler.createObserver(String.self)
        let balancesObserver = scheduler.createObserver([Balance].self)
        let transactionsObserver = scheduler.createObserver([Transaction].self)
        
        viewModel.output.totalBalance
            .subscribe(totalBalanceObserver)
            .disposed(by: disposeBag)
        
        viewModel.output.balances
            .subscribe(balancesObserver)
            .disposed(by: disposeBag)
        
        viewModel.output.transactions
            .subscribe(transactionsObserver)
            .disposed(by: disposeBag)
        
        // 触发刷新
        viewModel.input.refreshTrigger.accept(())
        
        scheduler.start()
        
        // 验证输出
        XCTAssertTrue(totalBalanceObserver.events.count > 0)
        XCTAssertTrue(balancesObserver.events.count > 0)
        XCTAssertTrue(transactionsObserver.events.count > 0)
    }
    
    // MARK: - SendViewModel Tests
    
    func testSendViewModelValidation() {
        let wallet = Wallet(
            address: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            network: Network.sepolia
        )
        
        let mockEstimateGasUseCase = MockEstimateGasUseCase()
        let viewModel = SendViewModel(wallet: wallet, estimateGasUseCase: mockEstimateGasUseCase)
        
        let isSendEnabledObserver = scheduler.createObserver(Bool.self)
        let errorObserver = scheduler.createObserver(String.self)
        
        viewModel.output.isSendEnabled
            .subscribe(isSendEnabledObserver)
            .disposed(by: disposeBag)
        
        viewModel.output.error
            .subscribe(errorObserver)
            .disposed(by: disposeBag)
        
        // 测试无效地址
        viewModel.input.toAddress.accept("invalid_address")
        viewModel.input.amount.accept("0.1")
        
        scheduler.start()
        
        XCTAssertFalse(isSendEnabledObserver.events.last?.value.element ?? true)
    }
    
    func testSendViewModelValidInput() {
        let wallet = Wallet(
            address: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            network: Network.sepolia
        )
        
        let mockEstimateGasUseCase = MockEstimateGasUseCase()
        let viewModel = SendViewModel(wallet: wallet, estimateGasUseCase: mockEstimateGasUseCase)
        
        let isSendEnabledObserver = scheduler.createObserver(Bool.self)
        
        viewModel.output.isSendEnabled
            .subscribe(isSendEnabledObserver)
            .disposed(by: disposeBag)
        
        // 测试有效输入
        viewModel.input.toAddress.accept("0x1234567890123456789012345678901234567890")
        viewModel.input.amount.accept("0.1")
        
        scheduler.start()
        
        XCTAssertTrue(isSendEnabledObserver.events.last?.value.element ?? false)
    }
}

// MARK: - Mock Use Cases

class MockResolveBalancesUseCase: ResolveBalancesUseCaseProtocol {
    func resolveBalances(for wallet: Wallet, currencies: [Currency]) -> Observable<[Balance]> {
        let mockBalances = currencies.map { currency in
            Balance(currency: currency, amount: Decimal(string: "1.0") ?? 0)
        }
        return Observable.just(mockBalances)
    }
}

class MockFetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol {
    func fetchTransactionHistory(for wallet: Wallet, limit: Int) -> Observable<[Transaction]> {
        let mockTransaction = Transaction(
            hash: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            from: wallet.address,
            to: "0x1234567890123456789012345678901234567890",
            amount: Decimal(string: "0.1") ?? 0,
            currency: Currency.eth,
            status: .success,
            direction: .outbound,
            timestamp: Date(),
            network: wallet.network
        )
        return Observable.just([mockTransaction])
    }
}

class MockEstimateGasUseCase: EstimateGasUseCaseProtocol {
    func estimateGas(from: String, to: String, amount: Decimal, currency: Currency, network: Network) -> Observable<GasEstimate> {
        let estimate = GasEstimate(
            gasLimit: 21000,
            gasPrice: 20,
            feeInETH: Decimal(string: "0.00042") ?? 0,
            feeInUSD: Decimal(string: "1.05") ?? 0
        )
        return Observable.just(estimate)
    }
}
