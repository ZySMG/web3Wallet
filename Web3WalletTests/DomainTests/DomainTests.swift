//
//  DomainTests.swift
//  Web3WalletTests
//
//  Created by Web3Wallet on 2025/01/01.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import Web3Wallet

class DomainTests: XCTestCase {
    
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
    
    // MARK: - GenerateMnemonicUseCase Tests
    
    func testGenerateMnemonic() {
        let useCase = GenerateMnemonicUseCase()
        let observer = scheduler.createObserver(String.self)
        
        useCase.generateMnemonic()
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.count, 2) // Next + Completed
        let mnemonic = observer.events.first?.value.element
        XCTAssertNotNil(mnemonic)
        XCTAssertTrue(mnemonic!.components(separatedBy: " ").count == 12)
    }
    
    func testGenerateWallet() {
        let useCase = GenerateMnemonicUseCase()
        let testMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let network = Network.sepolia
        let observer = scheduler.createObserver(Wallet.self)
        
        useCase.generateWallet(from: testMnemonic, network: network)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.count, 2) // Next + Completed
        let wallet = observer.events.first?.value.element
        XCTAssertNotNil(wallet)
        XCTAssertEqual(wallet?.network, network)
        XCTAssertFalse(wallet?.isImported ?? true)
    }
    
    // MARK: - EstimateGasUseCase Tests
    
    func testEstimateGas() {
        let mockEthereumService = MockEthereumService()
        let mockPriceService = MockPriceService()
        let useCase = EstimateGasUseCase(
            ethereumService: mockEthereumService,
            priceService: mockPriceService
        )
        
        let observer = scheduler.createObserver(GasEstimate.self)
        
        useCase.estimateGas(
            from: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            to: "0x1234567890123456789012345678901234567890",
            amount: Decimal(string: "0.1") ?? 0,
            currency: Currency.eth,
            network: Network.sepolia
        )
        .subscribe(observer)
        .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.count, 2) // Next + Completed
        let estimate = observer.events.first?.value.element
        XCTAssertNotNil(estimate)
        XCTAssertEqual(estimate?.gasLimit, 21000)
        XCTAssertEqual(estimate?.gasPrice, 20)
    }
    
    // MARK: - Balance Tests
    
    func testBalanceFormatting() {
        let balance = Balance(
            currency: Currency.eth,
            amount: Decimal(string: "1.234567890123456789") ?? 0,
            usdValue: Decimal(string: "2500.123456") ?? 0
        )
        
        XCTAssertEqual(balance.formattedAmount, "1.234567890123456789")
        XCTAssertEqual(balance.formattedUSDValue, "$2500.12")
        XCTAssertTrue(balance.isValid)
    }
    
    func testBalanceWithZeroAmount() {
        let balance = Balance(
            currency: Currency.eth,
            amount: 0,
            usdValue: nil
        )
        
        XCTAssertFalse(balance.isValid)
        XCTAssertEqual(balance.formattedUSDValue, "N/A")
    }
    
    // MARK: - Transaction Tests
    
    func testTransactionFormatting() {
        let transaction = Transaction(
            hash: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            from: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            to: "0x1234567890123456789012345678901234567890",
            amount: Decimal(string: "0.1") ?? 0,
            currency: Currency.eth,
            gasUsed: Decimal(string: "21000") ?? 0,
            gasPrice: Decimal(string: "20000000000") ?? 0,
            status: .success,
            direction: .outbound,
            timestamp: Date(),
            blockNumber: 12345678,
            network: Network.sepolia
        )
        
        XCTAssertTrue(transaction.formattedAmount.contains("-"))
        XCTAssertTrue(transaction.formattedAmount.contains("0.1"))
        XCTAssertTrue(transaction.formattedAmount.contains("ETH"))
        XCTAssertTrue(transaction.isOutbound)
        XCTAssertFalse(transaction.isInbound)
    }
    
    func testTransactionExplorerURL() {
        let transaction = Transaction(
            hash: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            from: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            to: "0x1234567890123456789012345678901234567890",
            amount: Decimal(string: "0.1") ?? 0,
            currency: Currency.eth,
            status: .success,
            direction: .outbound,
            timestamp: Date(),
            network: Network.sepolia
        )
        
        let expectedURL = "https://sepolia.etherscan.io/tx/0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        XCTAssertEqual(transaction.explorerURL, expectedURL)
    }
}
