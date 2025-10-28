//
//  WalletHomeViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Wallet home view controller
/// Responsibilities: Display main wallet features including buttons and asset list
class WalletHomeViewController: UIViewController {
    
    var viewModel: WalletHomeViewModel!
    var appContainer: AppContainer!
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let accountButton = UIButton(type: .system)
    private let balanceCardView = UIView()
    private let balanceLabel = UILabel()
    private let actionButtonsStackView = UIStackView()
    private let receiveButton = UIButton(type: .system)
    let sendButton = UIButton(type: .system) // 改为public以便Coordinator访问
    private let transactionButton = UIButton(type: .system)
    private let networkButton = UIButton(type: .system)
    private let tokenListTitleLabel = UILabel()
    private let tokenListView = TokenListView()
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupNetworkStatusMonitoring()
    }
    
    private func setupUI() {
        // 设置背景色
        view.backgroundColor = UIColor.systemBackground
        
        // 设置滚动视图
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // 设置标题
        titleLabel.text = "Web3Wallet"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        
        // 设置账户按钮
        accountButton.setTitle("账户 1", for: .normal)
        accountButton.setTitleColor(UIColor.systemBlue, for: .normal)
        accountButton.backgroundColor = UIColor.systemGray6
        accountButton.layer.cornerRadius = 8
        
        // 设置余额卡片
        balanceCardView.backgroundColor = UIColor.systemBlue
        balanceCardView.layer.cornerRadius = 16
        
        balanceLabel.text = "总资产: $0.00"
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 20)
        balanceLabel.textColor = UIColor.white
        balanceLabel.textAlignment = .center
        
        // 设置操作按钮
        setupActionButtons()
        
        // 设置网络按钮
        setupNetworkButton()
        
        // 设置代币列表标题
        tokenListTitleLabel.text = "我的资产"
        tokenListTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        tokenListTitleLabel.textColor = UIColor.label
        
        // 添加子视图
        contentView.addSubview(titleLabel)
        contentView.addSubview(accountButton)
        contentView.addSubview(balanceCardView)
        balanceCardView.addSubview(balanceLabel)
        contentView.addSubview(actionButtonsStackView)
        contentView.addSubview(networkButton)
        contentView.addSubview(tokenListTitleLabel)
        contentView.addSubview(tokenListView)
        
        // 设置约束
        setupConstraints()
    }
    
    private func setupActionButtons() {
        // Configure buttons
        receiveButton.setTitle("Receive", for: .normal)
        receiveButton.backgroundColor = UIColor.systemGreen
        receiveButton.setTitleColor(.white, for: .normal)
        receiveButton.layer.cornerRadius = 8
        receiveButton.isHidden = false // Re-enable receive button
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.backgroundColor = UIColor.systemBlue
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 8
        // Send button is now enabled for faucet testing
        
        transactionButton.setTitle("Transaction History", for: .normal)
        transactionButton.backgroundColor = UIColor.systemOrange
        transactionButton.setTitleColor(.white, for: .normal)
        transactionButton.layer.cornerRadius = 8
        transactionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        transactionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        transactionButton.titleLabel?.minimumScaleFactor = 0.8
        transactionButton.titleLabel?.numberOfLines = 1
        
        // Set button height
        [receiveButton, sendButton, transactionButton].forEach { button in
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        // Setup stack view
        actionButtonsStackView.axis = .horizontal
        actionButtonsStackView.distribution = .fillEqually
        actionButtonsStackView.spacing = 12
        actionButtonsStackView.addArrangedSubview(receiveButton)
        actionButtonsStackView.addArrangedSubview(sendButton)
        actionButtonsStackView.addArrangedSubview(transactionButton)
    }
    
    private func setupNetworkButton() {
        networkButton.setTitle("Ethereum Mainnet", for: .normal)
        networkButton.backgroundColor = UIColor.systemGray5
        networkButton.setTitleColor(.label, for: .normal)
        networkButton.layer.cornerRadius = 8
        networkButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        networkButton.contentHorizontalAlignment = .left
        networkButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        
        // 添加箭头图标
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        arrowImageView.tintColor = UIColor.systemGray
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        networkButton.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            arrowImageView.trailingAnchor.constraint(equalTo: networkButton.trailingAnchor, constant: -12),
            arrowImageView.centerYAnchor.constraint(equalTo: networkButton.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func setupConstraints() {
        [titleLabel, accountButton, balanceCardView, balanceLabel, actionButtonsStackView, networkButton, tokenListTitleLabel, tokenListView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // 滚动视图约束
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 内容视图约束
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 标题约束
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 账户按钮约束
            accountButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            accountButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            accountButton.widthAnchor.constraint(equalToConstant: 80),
            accountButton.heightAnchor.constraint(equalToConstant: 36),
            
            // 余额卡片约束
            balanceCardView.topAnchor.constraint(equalTo: accountButton.bottomAnchor, constant: 20),
            balanceCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            balanceCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            balanceCardView.heightAnchor.constraint(equalToConstant: 80),
            
            // 余额标签约束
            balanceLabel.centerXAnchor.constraint(equalTo: balanceCardView.centerXAnchor),
            balanceLabel.centerYAnchor.constraint(equalTo: balanceCardView.centerYAnchor),
            
            // 操作按钮约束
            actionButtonsStackView.topAnchor.constraint(equalTo: balanceCardView.bottomAnchor, constant: 20),
            actionButtonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionButtonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 网络按钮约束
            networkButton.topAnchor.constraint(equalTo: actionButtonsStackView.bottomAnchor, constant: 16),
            networkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            networkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            networkButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 代币列表标题约束
            tokenListTitleLabel.topAnchor.constraint(equalTo: networkButton.bottomAnchor, constant: 20),
            tokenListTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tokenListTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 代币列表约束
            tokenListView.topAnchor.constraint(equalTo: tokenListTitleLabel.bottomAnchor, constant: 10),
            tokenListView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tokenListView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tokenListView.heightAnchor.constraint(equalToConstant: 300),
            tokenListView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        // 绑定刷新
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.input.refreshTrigger)
            .disposed(by: disposeBag)
        
        // 绑定余额
        viewModel.output.totalBalance
            .drive(balanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 绑定代币列表
        viewModel.output.balances
            .drive(tokenListView.rx.balances)
            .disposed(by: disposeBag)
        
        // 绑定当前网络
        viewModel.output.currentNetwork
            .drive(networkButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        // 绑定账户名称
        viewModel.output.accountName
            .drive(accountButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        // 绑定加载状态
        viewModel.output.isLoading
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        // 绑定错误
        viewModel.output.error
            .drive(onNext: { [weak self] error in
                self?.showErrorAlert(error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        // 绑定导航事件
        viewModel.output.showSend
            .drive(onNext: { [weak self] wallet in
                self?.showSend(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.showTransactionHistory
            .drive(onNext: { [weak self] wallet in
                self?.showTransactionHistory(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.showWalletManagement
            .drive(onNext: { [weak self] in
                self?.showWalletManagement()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.showNetworkSelection
            .drive(onNext: { [weak self] in
                self?.showNetworkSelection()
            })
            .disposed(by: disposeBag)
        
        // 绑定按钮事件
        receiveButton.rx.tap
            .bind(to: viewModel.input.receiveTrigger)
            .disposed(by: disposeBag)
        
        // Send按钮绑定已移至WalletCoordinator中处理，避免重复导航
        
        transactionButton.rx.tap
            .bind(to: viewModel.input.transactionTrigger)
            .disposed(by: disposeBag)
        
        networkButton.rx.tap
            .bind(to: viewModel.input.networkSwitchTrigger)
            .disposed(by: disposeBag)
        
        accountButton.rx.tap
            .bind(to: viewModel.input.walletManagementTrigger)
            .disposed(by: disposeBag)
        
        // 监听钱包切换通知
        NotificationCenter.default.rx
            .notification(.walletSwitched)
            .compactMap { $0.object as? Wallet }
            .subscribe(onNext: { [weak self] wallet in
                self?.viewModel.switchToWallet(wallet)
            })
            .disposed(by: disposeBag)
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSend(wallet: Wallet) {
        let sendVC = SendViewController()
        let sendTransactionUseCase = SendTransactionUseCase(ethereumService: appContainer.ethereumService)
        let sendVM = SendViewModel(
            wallet: wallet, 
            estimateGasUseCase: appContainer.estimateGasUseCase,
            ethereumService: appContainer.ethereumService,
            sendTransactionUseCase: sendTransactionUseCase
        )
        sendVC.viewModel = sendVM
        
        navigationController?.pushViewController(sendVC, animated: true)
    }
    
    private func showTransactionHistory(wallet: Wallet) {
        let transactionVC = TransactionHistoryViewController()
        // Get fetchTxHistoryUseCase from AppContainer
        // TODO: Implement real FetchTxHistoryUseCase with proper dependencies
        let txService = TxService(networkService: NetworkService())
        let cacheService = CacheService()
        
        // ✅ 使用WalletManagerSingleton的当前钱包，而不是传入的wallet
        guard let currentWallet = WalletManagerSingleton.shared.currentWalletSubject.value else {
            print("❌ No current wallet found in WalletManagerSingleton")
            return
        }
        
        let transactionVM = TransactionHistoryViewModel(
            wallet: currentWallet,
            fetchTxHistoryUseCase: FetchTxHistoryUseCase(txService: txService, cacheService: cacheService)
        )
        transactionVC.viewModel = transactionVM
        
        navigationController?.pushViewController(transactionVC, animated: true)
    }
    
    private func showNetworkSelection() {
        let networkVC = NetworkSelectionViewController()
        networkVC.setCurrentNetwork(viewModel.getCurrentNetwork())
        networkVC.onNetworkSelected = { [weak self] network in
            self?.viewModel.switchNetwork(to: network)
        }
        
        let navController = UINavigationController(rootViewController: networkVC)
        present(navController, animated: true)
    }
    
    private func showWalletManagement() {
        let walletManagementVC = WalletManagementViewController()
        let walletManagementVM = WalletManagementViewModel(
            keychainStorage: KeychainStorageService(),
            generateMnemonicUseCase: GenerateMnemonicUseCase(),
            importWalletUseCase: ImportWalletUseCase()
        )
        walletManagementVC.viewModel = walletManagementVM
        
        let navController = UINavigationController(rootViewController: walletManagementVC)
        present(navController, animated: true)
    }
    
    // MARK: - Network Status Monitoring
    
    private func setupNetworkStatusMonitoring() {
        guard let appContainer = appContainer else { return }
        
        // Monitor airplane mode
        appContainer.networkStatusService.isAirplaneMode
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isAirplaneMode in
                if isAirplaneMode {
                    self?.showAirplaneModeAlert()
                }
            })
            .disposed(by: disposeBag)
        
        // Monitor network connection
        appContainer.networkStatusService.isConnected
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isConnected in
                if !isConnected {
                    self?.showNetworkDisconnectedAlert()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func showAirplaneModeAlert() {
        guard let appContainer = appContainer else { return }
        appContainer.networkStatusService.showAirplaneModeAlert(from: self)
    }
    
    private func showNetworkDisconnectedAlert() {
        guard let appContainer = appContainer else { return }
        appContainer.networkStatusService.showNetworkDisconnectedAlert(from: self)
    }
}

// MARK: - Reactive Extensions
extension Reactive where Base: UILabel {
    var text: Binder<String> {
        return Binder(base) { label, text in
            label.text = text
        }
    }
}
