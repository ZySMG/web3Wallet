//
//  OnboardingCoordinator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Onboarding coordinator
class OnboardingCoordinator: BaseCoordinator {
    
    private let disposeBag = DisposeBag()
    
    override func start() {
        showWelcome()
    }
    
    private func showWelcome() {
        let welcomeVC = WelcomeViewController()
        let welcomeVM = WelcomeViewModel()
        welcomeVC.viewModel = welcomeVM
        
        // Bind events
        welcomeVM.output.showCreateWallet
            .drive(onNext: { [weak self] in
                self?.showCreateWallet()
            })
            .disposed(by: disposeBag)
        
        welcomeVM.output.showImportWallet
            .drive(onNext: { [weak self] in
                self?.showImportWallet()
            })
            .disposed(by: disposeBag)
        
        navigationController.setViewControllers([welcomeVC], animated: false)
    }
    
    private func showCreateWallet() {
        let createVC = CreateWalletViewController()
        let createVM = CreateWalletViewModel()
        createVC.viewModel = createVM
        
        // Bind events
        createVM.output.showMnemonic
            .drive(onNext: { [weak self] mnemonic in
                self?.showMnemonic(mnemonic: mnemonic)
            })
            .disposed(by: disposeBag)
        
        createVM.output.walletCreated
            .drive(onNext: { [weak self] wallet in
                self?.onWalletCreated(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        navigationController.pushViewController(createVC, animated: true)
    }
    
    private func showImportWallet() {
        let importVC = ImportWalletViewController()
        
        // Set callback
        importVC.onWalletImported = { [weak self] wallet in
            self?.onWalletImported(wallet: wallet)
        }
        
        navigationController.pushViewController(importVC, animated: true)
    }
    
    private func showMnemonic(mnemonic: String) {
        let mnemonicVC = MnemonicViewController()
        let mnemonicVM = MnemonicViewModel(mnemonic: mnemonic)
        mnemonicVC.viewModel = mnemonicVM
        
        // Bind events
        mnemonicVM.output.walletCreated
            .drive(onNext: { [weak self] wallet in
                self?.onWalletCreated(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        navigationController.pushViewController(mnemonicVC, animated: true)
    }
    
    private func onWalletCreated(wallet: Wallet) {
        // Notify parent coordinator wallet created
        NotificationCenter.default.post(name: .walletCreated, object: wallet)
    }
    
    private func onWalletImported(wallet: Wallet) {
        // Notify parent coordinator wallet imported
        NotificationCenter.default.post(name: .walletImported, object: wallet)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let walletCreated = Notification.Name("walletCreated")
    static let walletImported = Notification.Name("walletImported")
    static let walletAddedToManagement = Notification.Name("walletAddedToManagement")
}
