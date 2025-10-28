//
//  WalletCoordinator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Wallet coordinator
class WalletCoordinator: BaseCoordinator {
    
    private let disposeBag = DisposeBag()
    private let wallet: Wallet
    private let appContainer: AppContainer
    
    init(navigationController: UINavigationController, wallet: Wallet, appContainer: AppContainer) {
        self.wallet = wallet
        self.appContainer = appContainer
        super.init(navigationController: navigationController)
    }
    
    override func start() {
        showWalletHome()
    }
    
    private func showWalletHome() {
        let homeVC = WalletHomeViewController()
        let homeVM = WalletHomeViewModel(
            wallet: wallet,
            resolveBalancesUseCase: appContainer.resolveBalancesUseCase,
            fetchTxHistoryUseCase: appContainer.fetchTxHistoryUseCase,
            priceService: appContainer.priceService
        )
        homeVC.viewModel = homeVM
        homeVC.appContainer = appContainer // 设置appContainer
        
        // Bind events
        homeVM.output.showReceive
            .drive(onNext: { [weak self] wallet in
                self?.showReceive(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        homeVM.output.showSend
            .drive(onNext: { [weak self] wallet in
                self?.showSend(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        homeVM.output.showTransaction
            .drive(onNext: { [weak self] transaction in
                self?.showTransactionDetail(transaction: transaction)
            })
            .disposed(by: disposeBag)
        
        // Bind Send button click event
        homeVC.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.showSend(wallet: self.wallet)
            })
            .disposed(by: disposeBag)
        
        navigationController.setViewControllers([homeVC], animated: false)
    }
    
    private func showReceive(wallet: Wallet) {
        let receiveVC = ReceiveViewController()
        let receiveVM = ReceiveViewModel(wallet: wallet)
        receiveVC.viewModel = receiveVM
        receiveVC.wallet = wallet // 设置wallet属性
        
        navigationController.pushViewController(receiveVC, animated: true)
    }
    
    private func showSend(wallet: Wallet) {
        // Show currency selection
        showCurrencySelection(for: wallet)
    }
    
    private func showCurrencySelection(for wallet: Wallet) {
        let alert = UIAlertController(title: "Select Currency", message: "Choose the currency you want to send", preferredStyle: .actionSheet)
        
        // Add ETH option
        alert.addAction(UIAlertAction(title: "ETH", style: .default) { [weak self] _ in
            self?.showSendViewController(wallet: wallet, currency: Currency.eth)
        })
        
        // Add USDC option
        alert.addAction(UIAlertAction(title: "USDC", style: .default) { [weak self] _ in
            self?.showSendViewController(wallet: wallet, currency: Currency.usdc)
        })
        
        // Add USDT option
        alert.addAction(UIAlertAction(title: "USDT", style: .default) { [weak self] _ in
            self?.showSendViewController(wallet: wallet, currency: Currency.usdt)
        })
        
        // Add cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Set popover for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = navigationController.view
            popover.sourceRect = CGRect(x: navigationController.view.bounds.midX, y: navigationController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        navigationController.present(alert, animated: true)
    }
    
    private func showSendViewController(wallet: Wallet, currency: Currency) {
        let sendVC = SendViewController()
        let sendTransactionUseCase = SendTransactionUseCase(ethereumService: appContainer.ethereumService)
        
        // ✅ Use WalletManagerSingleton current wallet instead of passed wallet
        guard let currentWallet = WalletManagerSingleton.shared.currentWalletSubject.value else {
            print("❌ No current wallet found in WalletManagerSingleton")
            return
        }
        
        let sendVM = SendViewModel(
            wallet: currentWallet, 
            estimateGasUseCase: appContainer.estimateGasUseCase, 
            ethereumService: appContainer.ethereumService,
            sendTransactionUseCase: sendTransactionUseCase,
            selectedCurrency: currency
        )
        sendVC.viewModel = sendVM
        
        navigationController.pushViewController(sendVC, animated: true)
    }
    
    private func showTransactionDetail(transaction: Transaction) {
        let txDetailVC = TransactionDetailViewController()
        let txDetailVM = TransactionDetailViewModel(transaction: transaction)
        txDetailVC.viewModel = txDetailVM
        
        navigationController.pushViewController(txDetailVC, animated: true)
    }
}
