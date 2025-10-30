//
//  ApplicationCoordinator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Application coordinator
class ApplicationCoordinator: BaseCoordinator {
    
    private let disposeBag = DisposeBag()
    private let appContainer: AppContainer
    
    override init(navigationController: UINavigationController) {
        self.appContainer = AppContainer()
        super.init(navigationController: navigationController)
    }
    
    override func start() {
        // Check if there are existing wallets
        if WalletManagerSingleton.shared.hasWallets() {
            showWalletHome()
        } else {
            showOnboarding()
        }
        
        // Listen to wallet creation/import events
        setupWalletNotifications()
    }
    
    private func hasExistingWallet() -> Bool {
        // Use WalletManagerSingleton to check if there are wallets
        return WalletManagerSingleton.shared.hasWallets()
    }
    
    private func showOnboarding() {
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        addChildCoordinator(onboardingCoordinator)
        onboardingCoordinator.start()
    }
    
    private func showWalletHome(using walletOverride: Wallet? = nil) {
        // Prefer explicit wallet, then current wallet, then first stored wallet
        let wallet = walletOverride
            ?? WalletManagerSingleton.shared.currentWalletSubject.value
            ?? WalletManagerSingleton.shared.allWalletsSubject.value.first
        
        guard let wallet else {
            showOnboarding()
            return
        }
        
        let walletCoordinator = WalletCoordinator(
            navigationController: navigationController,
            wallet: wallet,
            appContainer: appContainer
        )
        addChildCoordinator(walletCoordinator)
        walletCoordinator.start()
    }
    
    private func setupWalletNotifications() {
        NotificationCenter.default.rx
            .notification(.walletCreated)
            .subscribe(onNext: { [weak self] notification in
                self?.handleWalletCreated(notification.object as? Wallet)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.walletImported)
            .subscribe(onNext: { [weak self] notification in
                self?.handleWalletImported(notification.object as? Wallet)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.navigateToWelcome)
            .subscribe(onNext: { [weak self] _ in
                self?.navigateToWelcome()
            })
            .disposed(by: disposeBag)
    }
    
    private func handleWalletCreated(_ wallet: Wallet?) {
        guard let wallet = wallet else { return }
        
        // ✅ Use WalletManagerSingleton to add wallet
        WalletManagerSingleton.shared.addWallet(wallet)
        
        // Switch to wallet home page
        removeAllChildCoordinators()
        showWalletHome(using: wallet)
    }
    
    private func handleWalletImported(_ wallet: Wallet?) {
        guard let wallet = wallet else { return }
        
        // ✅ Use WalletManagerSingleton to add wallet
        WalletManagerSingleton.shared.addWallet(wallet)
        
        // Switch to wallet home page
        removeAllChildCoordinators()
        showWalletHome(using: wallet)
    }
    
    private func navigateToWelcome() {
        // Clear all child coordinators
        childCoordinators.removeAll()
        
        // Navigate to welcome screen
        showOnboarding()
    }
}
