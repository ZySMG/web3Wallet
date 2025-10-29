//
//  ViewModelTests.swift
//  Web3WalletTests
//
//  Created by Codex on 2025/01/17.
//

import XCTest
import UIKit
import RxSwift
import RxCocoa
@testable import trust_wallet2

final class ViewModelTests: XCTestCase {
    
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }
    
    func testSmoke() {
        XCTAssertTrue(true)
    }
    
    // MARK: - SendViewModel
    
    func testSendViewModelLoadsBalanceOnInit() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let estimateGas = StubEstimateGasUseCase()
        let ethereumService = StubEthereumService()
        let balanceSubject = PublishSubject<Decimal>()
        ethereumService.balanceResult = balanceSubject.asObservable()
        let sendUseCase = StubSendTransactionUseCase()
        
        let viewModel = SendViewModel(
            wallet: wallet,
            estimateGasUseCase: estimateGas,
            ethereumService: ethereumService,
            sendTransactionUseCase: sendUseCase
        )
        
        let expectation = expectation(description: "Balance updated")
        var latestValue: String?
        viewModel.output.balance
            .asObservable()
            .skip(1)
            .subscribe(onNext: { value in
                latestValue = value
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        DispatchQueue.main.async {
            balanceSubject.onNext(Decimal(2))
            balanceSubject.onCompleted()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(latestValue, "Balance: 2.000000 ETH")
    }
    
    func testSendViewModelUpdateWalletResetsInputs() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let estimateGas = StubEstimateGasUseCase()
        let ethereumService = StubEthereumService()
        let sendUseCase = StubSendTransactionUseCase()
        
        let viewModel = SendViewModel(
            wallet: wallet,
            estimateGasUseCase: estimateGas,
            ethereumService: ethereumService,
            sendTransactionUseCase: sendUseCase
        )
        
        viewModel.input.toAddress.accept("0x2222222222222222222222222222222222222222")
        viewModel.input.amount.accept("1.5")
        
        let newWallet = Wallet(address: "0x3333333333333333333333333333333333333333", network: .ethereumMainnet)
        viewModel.updateWallet(newWallet)
        
        XCTAssertEqual(viewModel.input.toAddress.value, "")
        XCTAssertEqual(viewModel.input.amount.value, "")
    }
    
    func testSendViewModelEmitsInsufficientBalanceMessage() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let estimateGas = StubEstimateGasUseCase()
        estimateGas.gasLimit = Decimal(21000)
        let ethereumService = StubEthereumService()
        ethereumService.balanceResult = .just(Decimal(0.5))
        let sendUseCase = StubSendTransactionUseCase()
        
        let viewModel = SendViewModel(
            wallet: wallet,
            estimateGasUseCase: estimateGas,
            ethereumService: ethereumService,
            sendTransactionUseCase: sendUseCase
        )
        
        let expectation = expectation(description: "Insufficient balance message emitted")
        var latestMessage: String?
        
        viewModel.output.insufficientBalanceMessage
            .asObservable()
            .skip(1)
            .subscribe(onNext: { message in
                if !message.isEmpty {
                    latestMessage = message
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.input.toAddress.accept("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb")
        let gasEstimate = GasEstimate(
            gasLimit: Decimal(21000),
            gasPrice: Decimal(20),
            feeInETH: Decimal(0.00042)
        )
        viewModel.currentGasEstimateSubject.accept(gasEstimate)
        viewModel.input.amount.accept("1")
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(latestMessage, "Insufficient balance. Need 1.000420 ETH, have 0.500000 ETH")
    }
    
    func testSendViewModelInvalidAddressShowsValidationMessage() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let estimateGas = StubEstimateGasUseCase()
        let ethereumService = StubEthereumService()
        let sendUseCase = StubSendTransactionUseCase()
        
        let viewModel = SendViewModel(
            wallet: wallet,
            estimateGasUseCase: estimateGas,
            ethereumService: ethereumService,
            sendTransactionUseCase: sendUseCase
        )
        
        let expectation = expectation(description: "Invalid address validation emitted")
        var latestMessage: String?
        
        viewModel.output.addressValidation
            .asObservable()
            .skip(1)
            .subscribe(onNext: { message in
                latestMessage = message
                if message.contains("Invalid") {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.input.toAddress.accept("not-an-address")
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(latestMessage, "✗ Invalid address format")
    }
    
    // MARK: - ReceiveViewModel
    
    func testReceiveViewModelOutputsWalletAddress() {
        let wallet = Wallet(address: "0x9999999999999999999999999999999999999999", network: .sepolia)
        let viewModel = ReceiveViewModel(wallet: wallet)
        
        var capturedAddress: String?
        var qrCodeImage: UIImage?
        
        viewModel.output.address
            .drive(onNext: { capturedAddress = $0 })
            .disposed(by: disposeBag)
        
        viewModel.output.qrCodeImage
            .drive(onNext: { qrCodeImage = $0 })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(capturedAddress, wallet.address)
        XCTAssertNotNil(qrCodeImage)
    }
    
    // MARK: - WelcomeViewModel
    
    func testWelcomeViewModelEmitsCreateEvent() {
        let viewModel = WelcomeViewModel()
        let expectation = expectation(description: "Create wallet tapped")
        
        viewModel.output.showCreateWallet
            .drive(onNext: { expectation.fulfill() })
            .disposed(by: disposeBag)
        
        viewModel.input.createWalletTrigger.accept(())
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testWelcomeViewModelEmitsImportEvent() {
        let viewModel = WelcomeViewModel()
        let expectation = expectation(description: "Import wallet tapped")
        
        viewModel.output.showImportWallet
            .drive(onNext: { expectation.fulfill() })
            .disposed(by: disposeBag)
        
        viewModel.input.importWalletTrigger.accept(())
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    // MARK: - WalletHomeViewModel
    
    func testWalletHomeViewModelSwitchNetworkUpdatesOutput() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let resolveUseCase = StubResolveBalancesUseCase()
        let fetchUseCase = StubFetchTxHistoryUseCase()
        let priceService = StubPriceService()
        
        let viewModel = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: resolveUseCase,
            fetchTxHistoryUseCase: fetchUseCase,
            priceService: priceService
        )
        
        let expectation = expectation(description: "Network updated")
        viewModel.output.currentNetwork
            .asObservable()
            .skip(1)
            .subscribe(onNext: { value in
                XCTAssertEqual(value, Network.ethereumMainnet.name)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        viewModel.switchNetwork(to: .ethereumMainnet)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWalletHomeViewModelShowsWalletManagement() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let resolveUseCase = StubResolveBalancesUseCase()
        let fetchUseCase = StubFetchTxHistoryUseCase()
        let priceService = StubPriceService()
        
        let viewModel = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: resolveUseCase,
            fetchTxHistoryUseCase: fetchUseCase,
            priceService: priceService
        )
        
        let expectation = expectation(description: "Wallet management navigation")
        viewModel.output.showWalletManagement
            .drive(onNext: { expectation.fulfill() })
            .disposed(by: disposeBag)
        
        viewModel.input.walletManagementTrigger.accept(())
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testWalletHomeViewModelEmitsNetworkErrorWhenOffline() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let resolveUseCase = StubResolveBalancesUseCase()
        let fetchUseCase = StubFetchTxHistoryUseCase()
        let priceService = StubPriceService()
        
        let offlineError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        
        let viewModel = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: resolveUseCase,
            fetchTxHistoryUseCase: fetchUseCase,
            priceService: priceService
        )
        
        let expectation = expectation(description: "Offline error emitted")
        var capturedError: WalletError?
        
        viewModel.output.error
            .drive(onNext: { error in
                guard let walletError = error as? WalletError else { return }
                capturedError = walletError
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            fetchUseCase.errorToReturn = offlineError
            viewModel.input.refreshTrigger.accept(())
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        guard case .networkError(let message)? = capturedError else {
            return XCTFail("Expected network error, got \(String(describing: capturedError))")
        }
        XCTAssertTrue(message.lowercased().contains("offline"))
    }
    
    func testWalletHomeViewModelEmitsRateLimitError() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let resolveUseCase = StubResolveBalancesUseCase()
        let fetchUseCase = StubFetchTxHistoryUseCase()
        let priceService = StubPriceService()
        
        let rateLimitError = NSError(domain: "com.web3wallet.test", code: 429, userInfo: [
            NSLocalizedDescriptionKey: "Too Many Requests"
        ])
        
        let viewModel = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: resolveUseCase,
            fetchTxHistoryUseCase: fetchUseCase,
            priceService: priceService
        )
        
        let expectation = expectation(description: "Rate limit error emitted")
        var capturedError: WalletError?
        
        viewModel.output.error
            .drive(onNext: { error in
                guard let walletError = error as? WalletError else { return }
                capturedError = walletError
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            priceService.tokenPricesError = rateLimitError
            viewModel.input.refreshTrigger.accept(())
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        guard case .networkError(let message)? = capturedError else {
            return XCTFail("Expected network error, got \(String(describing: capturedError))")
        }
        XCTAssertTrue(message.lowercased().contains("rate limit"))
    }
    
    // MARK: - CreateWalletViewModel
    
    func testCreateWalletViewModelEmitsMnemonic() {
        let generateUseCase = StubGenerateMnemonicUseCase()
        generateUseCase.mnemonicToReturn = "test mnemonic words"
        
        let viewModel = CreateWalletViewModel(generateMnemonicUseCase: generateUseCase)
        
        let expectation = expectation(description: "Mnemonic generated")
        viewModel.output.showMnemonic
            .drive(onNext: { mnemonic in
                XCTAssertEqual(mnemonic, "test mnemonic words")
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        viewModel.input.createTrigger.accept(())
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - MnemonicViewModel
    
    func testMnemonicViewModelConfirmCreatesWallet() {
        let generateUseCase = StubGenerateMnemonicUseCase()
        let expectedWallet = Wallet(address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", network: .sepolia)
        generateUseCase.walletToReturn = expectedWallet
        
        let viewModel = MnemonicViewModel(mnemonic: "seed words twelve", generateWalletUseCase: generateUseCase)
        
        let expectation = expectation(description: "Wallet created")
        viewModel.output.walletCreated
            .drive(onNext: { wallet in
                XCTAssertEqual(wallet.address, expectedWallet.address)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        viewModel.input.confirmTrigger.accept(())
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - WalletManagementViewModel
    
    func testWalletManagementViewModelWalletSelectionSetsCurrentWallet() {
        let keychain = InMemoryKeychainStorage()
        let generateUseCase = StubGenerateMnemonicUseCase()
        let importUseCase = StubImportWalletUseCase()
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let mockManager = MockWalletManager(initialWallets: [wallet], currentWallet: wallet)
        let suiteName = "wallet-management-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        
        let viewModel = WalletManagementViewModel(
            keychainStorage: keychain,
            generateMnemonicUseCase: generateUseCase,
            importWalletUseCase: importUseCase,
            walletManager: mockManager,
            userDefaults: userDefaults
        )
        
        viewModel.input.walletSelected.accept(wallet)
        
        XCTAssertEqual(mockManager.setCurrentWalletCalls.last?.address, wallet.address)
    }
    
    func testWalletManagementViewModelHandlesWalletAddedNotification() {
        let keychain = InMemoryKeychainStorage()
        let generateUseCase = StubGenerateMnemonicUseCase()
        let importUseCase = StubImportWalletUseCase()
        let existingWallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let mockManager = MockWalletManager(initialWallets: [existingWallet], currentWallet: existingWallet)
        let suiteName = "wallet-management-notification-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        
        let viewModel = WalletManagementViewModel(
            keychainStorage: keychain,
            generateMnemonicUseCase: generateUseCase,
            importWalletUseCase: importUseCase,
            walletManager: mockManager,
            userDefaults: userDefaults
        )
        
        let newWallet = Wallet(address: "0x2222222222222222222222222222222222222222", network: .ethereumMainnet)
        let expectation = expectation(description: "Wallet sections updated")
        
        viewModel.output.walletSections
            .asObservable()
            .skip(1)
            .subscribe(onNext: { sections in
                if sections.contains(where: { $0.wallet.address == newWallet.address }) {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.post(name: .walletAddedToManagement, object: newWallet)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockManager.addWalletCalls.last?.address, newWallet.address)
    }
    
    // MARK: - TransactionHistoryViewModel
    
    func testTransactionHistoryViewModelLoadsTransactions() {
        let wallet = Wallet(address: "0x1111111111111111111111111111111111111111", network: .sepolia)
        let fetchUseCase = StubFetchTxHistoryUseCase()
        let expectedTransaction = Transaction(
            hash: "0xhash",
            from: wallet.address,
            to: "0x2222222222222222222222222222222222222222",
            amount: Decimal(0.5),
            currency: .eth,
            status: .success,
            direction: .outbound,
            timestamp: Date(),
            network: wallet.network
        )
        fetchUseCase.transactionsToReturn = [expectedTransaction]
        
        let viewModel = TransactionHistoryViewModel(wallet: wallet, fetchTxHistoryUseCase: fetchUseCase)
        
        let expectation = expectation(description: "Transactions loaded")
        viewModel.output.transactions
            .asObservable()
            .filter { !$0.isEmpty }
            .subscribe(onNext: { transactions in
                XCTAssertEqual(transactions.first?.hash, expectedTransaction.hash)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - TransactionDetailViewModel
    
    func testTransactionDetailViewModelOutputsTransactionInfo() {
        let transaction = Transaction(
            hash: "0xhash",
            from: "0x111",
            to: "0x222",
            amount: Decimal(1),
            currency: .eth,
            status: .success,
            direction: .outbound,
            timestamp: Date(),
            network: .sepolia
        )
        
        let viewModel = TransactionDetailViewModel(transaction: transaction)
        XCTAssertNotNil(viewModel.output.status)
    }
}

// MARK: - GenerateMnemonicUseCase Tests

final class GenerateMnemonicUseCaseTests: XCTestCase {
    
    private var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }
    
    func testGenerateWalletFromKnownMnemonicMatchesExpectedAddress() {
        let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let expectedAddress = "0x9858effd232b4033e47d90003d41ec34ecaeda94"
        let useCase = GenerateMnemonicUseCase()
        
        let expectation = expectation(description: "Wallet generated from mnemonic")
        var generatedWallet: Wallet?
        
        useCase.generateWallet(from: mnemonic, network: .sepolia)
            .subscribe(onNext: { wallet in
                generatedWallet = wallet
                expectation.fulfill()
            }, onError: { error in
                XCTFail("Unexpected error: \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(generatedWallet?.address.lowercased(), expectedAddress.lowercased())
        XCTAssertEqual(generatedWallet?.network, .sepolia)
    }
    
    func testGenerateWalletRejectsInvalidMnemonic() {
        let invalidMnemonic = "this is not a valid mnemonic phrase"
        let useCase = GenerateMnemonicUseCase()
        
        let expectation = expectation(description: "Invalid mnemonic rejected")
        
        useCase.generateWallet(from: invalidMnemonic, network: .sepolia)
            .subscribe(onNext: { _ in
                XCTFail("Expected failure for invalid mnemonic")
            }, onError: { error in
                if case WalletError.invalidMnemonic = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Unexpected error type: \(error)")
                }
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - MnemonicValidator Tests

final class MnemonicValidatorTests: XCTestCase {
    
    func testMnemonicValidatorAcceptsValidSeedWords() {
        let validator = MnemonicValidator()
        let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        XCTAssertTrue(validator.isValid(mnemonic))
    }
    
    func testMnemonicValidatorRejectsInvalidWordCount() {
        let validator = MnemonicValidator()
        let mnemonic = "abandon abandon abandon"
        XCTAssertFalse(validator.validateWordCount(mnemonic))
    }
    
    func testMnemonicValidatorRejectsUnknownWords() {
        let validator = MnemonicValidator()
        let mnemonic = "hello world foo bar baz qux quux corge grault garply waldo fred"
        XCTAssertFalse(validator.validateWords(mnemonic))
    }
}

// MARK: - Test Doubles

final class StubEstimateGasUseCase: EstimateGasUseCaseProtocol {
    var gasLimit: Decimal = Decimal(21000)
    
    func estimateGas(from: String, to: String, amount: Decimal, currency: Currency, network: Network) -> Observable<Decimal> {
        return Observable.just(gasLimit)
    }
}

final class StubEthereumService: EthereumServiceProtocol {
    var nonceResult: Observable<Int> = .just(0)
    var gasPriceResult: Observable<Decimal> = .just(Decimal(20))
    var sendTransactionResult: Observable<String> = .just("0x0")
    var balanceResult: Observable<Decimal> = .never()
    
    func getNonce(address: String, network: Network) -> Observable<Int> {
        return nonceResult
    }
    
    func getGasPrice(network: Network) -> Observable<Decimal> {
        return gasPriceResult
    }
    
    func sendRawTransaction(rawTransaction: String, network: Network) -> Observable<String> {
        return sendTransactionResult
    }
    
    func getBalance(address: String, currency: Currency, network: Network) -> Observable<Decimal> {
        return balanceResult
    }
}

final class StubSendTransactionUseCase: SendTransactionUseCaseProtocol {
    var txHashToReturn: String = "0xtransaction"
    
    func sendTransaction(from wallet: Wallet, to address: String, amount: Decimal, currency: Currency, gasEstimate: GasEstimate, mnemonic: String) -> Observable<String> {
        return Observable.just(txHashToReturn)
    }
}

final class StubResolveBalancesUseCase: ResolveBalancesUseCaseProtocol {
    var balancesToReturn: [Balance] = [
        Balance(currency: .eth, amount: Decimal(0), usdValue: 0, lastUpdated: Date())
    ]
    var errorToReturn: Error?
    
    func resolveBalances(for wallet: Wallet, currencies: [Currency]) -> Observable<[Balance]> {
        if let error = errorToReturn {
            return Observable.error(error)
        }
        return Observable.just(balancesToReturn)
    }
}

final class StubFetchTxHistoryUseCase: FetchTxHistoryUseCaseProtocol {
    var transactionsToReturn: [Transaction] = []
    var errorToReturn: Error?
    
    func fetchTransactionHistory(for wallet: Wallet, limit: Int) -> Observable<[Transaction]> {
        if let error = errorToReturn {
            return Observable.error(error)
        }
        return Observable.just(transactionsToReturn)
    }
}

final class StubPriceService: PriceServiceProtocol {
    var ethPrice: Decimal = Decimal(2000)
    var tokenPrices: [String: Decimal] = [:]
    var priceHistory: [PricePoint] = []
    var tokenPricesError: Error?
    var priceHistoryError: Error?
    
    func getETHPrice() -> Observable<Decimal> {
        return Observable.just(ethPrice)
    }
    
    func getTokenPrices(currencies: [Currency]) -> Observable<[String : Decimal]> {
        if let error = tokenPricesError {
            return Observable.error(error)
        }
        return Observable.just(tokenPrices)
    }
    
    func getPriceHistory(currency: Currency, days: Int) -> Observable<[PricePoint]> {
        if let error = priceHistoryError {
            return Observable.error(error)
        }
        return Observable.just(priceHistory)
    }
}

final class StubGenerateMnemonicUseCase: GenerateMnemonicUseCaseProtocol {
    var mnemonicToReturn: String = "default mnemonic"
    var walletToReturn: Wallet = Wallet(address: "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef", network: .sepolia)
    
    func generateMnemonic() -> Observable<String> {
        return Observable.just(mnemonicToReturn)
    }
    
    func generateWallet(from mnemonic: String, network: Network) -> Observable<Wallet> {
        return Observable.just(walletToReturn)
    }
}

final class StubImportWalletUseCase: ImportWalletUseCaseProtocol {
    var walletToReturn: Wallet = Wallet(address: "0ximported", network: .sepolia, isImported: true)
    
    func importWallet(from mnemonic: String, network: Network) -> Observable<Wallet> {
        return Observable.just(walletToReturn)
    }
}

final class InMemoryKeychainStorage: KeychainStorageServiceProtocol {
    private var storage: [String: String] = [:]
    
    func store(key: String, value: String) -> Bool {
        storage[key] = value
        return true
    }
    
    func retrieve(key: String) -> String? {
        return storage[key]
    }
    
    func delete(key: String) -> Bool {
        storage.removeValue(forKey: key)
        return true
    }
    
    func exists(key: String) -> Bool {
        return storage[key] != nil
    }
}

final class MockWalletManager: WalletManaging {
    private let allWalletsRelay: BehaviorRelay<[Wallet]>
    private let currentWalletRelay: BehaviorRelay<Wallet?>
    
    var addWalletCalls: [Wallet] = []
    var removeWalletCalls: [Wallet] = []
    var setCurrentWalletCalls: [Wallet] = []
    var clearAllWalletsCalled = false
    
    init(initialWallets: [Wallet], currentWallet: Wallet?) {
        allWalletsRelay = BehaviorRelay(value: initialWallets)
        currentWalletRelay = BehaviorRelay(value: currentWallet)
    }
    
    var allWalletsDriver: Driver<[Wallet]> {
        return allWalletsRelay.asDriver()
    }
    
    var currentWalletDriver: Driver<Wallet?> {
        return currentWalletRelay.asDriver()
    }
    
    var allWalletsValue: [Wallet] {
        return allWalletsRelay.value
    }
    
    var currentWalletValue: Wallet? {
        return currentWalletRelay.value
    }
    
    func addWallet(_ wallet: Wallet) {
        addWalletCalls.append(wallet)
        var updated = allWalletsRelay.value
        updated.append(wallet)
        allWalletsRelay.accept(updated)
        if currentWalletRelay.value == nil {
            currentWalletRelay.accept(wallet)
        }
    }
    
    func removeWallet(_ wallet: Wallet) {
        removeWalletCalls.append(wallet)
        var updated = allWalletsRelay.value
        updated.removeAll { $0.address.lowercased() == wallet.address.lowercased() }
        allWalletsRelay.accept(updated)
        if currentWalletRelay.value?.address.lowercased() == wallet.address.lowercased() {
            currentWalletRelay.accept(updated.first)
        }
    }
    
    func clearAllWallets() {
        clearAllWalletsCalled = true
        allWalletsRelay.accept([])
        currentWalletRelay.accept(nil)
    }
    
    func setCurrentWallet(_ wallet: Wallet) {
        setCurrentWalletCalls.append(wallet)
        currentWalletRelay.accept(wallet)
    }
}
