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

/// 应用协调器
class ApplicationCoordinator: BaseCoordinator {
    
    private let disposeBag = DisposeBag()
    private let appContainer: AppContainer
    
    override init(navigationController: UINavigationController) {
        self.appContainer = AppContainer()
        super.init(navigationController: navigationController)
    }
    
    override func start() {
        // 检查是否有现有钱包
        if WalletManagerSingleton.shared.hasWallets() {
            showWalletHome()
        } else {
            showOnboarding()
        }
        
        // 监听钱包创建/导入事件
        setupWalletNotifications()
    }
    
    private func hasExistingWallet() -> Bool {
        // 使用WalletManagerSingleton检查是否有钱包
        return WalletManagerSingleton.shared.hasWallets()
    }
    
    private func showOnboarding() {
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        addChildCoordinator(onboardingCoordinator)
        onboardingCoordinator.start()
    }
    
    private func showWalletHome() {
        // 从 WalletManagerSingleton 获取当前钱包
        guard let wallet = WalletManagerSingleton.shared.currentWalletSubject.value else {
            // 如果没有钱包，显示入门流程
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
        
        // ✅ 使用WalletManagerSingleton添加钱包
        WalletManagerSingleton.shared.addWallet(wallet)
        
        // 切换到钱包首页
        removeAllChildCoordinators()
        showWalletHome()
    }
    
    private func handleWalletImported(_ wallet: Wallet?) {
        guard let wallet = wallet else { return }
        
        // ✅ 使用WalletManagerSingleton添加钱包
        WalletManagerSingleton.shared.addWallet(wallet)
        
        // 切换到钱包首页
        removeAllChildCoordinators()
        showWalletHome()
    }
    
    private func navigateToWelcome() {
        // Clear all child coordinators
        childCoordinators.removeAll()
        
        // Navigate to welcome screen
        showOnboarding()
    }
}
