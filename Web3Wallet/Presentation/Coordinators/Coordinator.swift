//
//  Coordinator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift

/// 协调器协议
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
    func finish()
}

/// 协调器基类
class BaseCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        fatalError("start() method must be implemented")
    }
    
    func finish() {
        childCoordinators.removeAll()
    }
    
    /// 添加子协调器
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    /// 移除子协调器
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
    
    /// 移除所有子协调器
    func removeAllChildCoordinators() {
        childCoordinators.removeAll()
    }
}

/// 协调器工厂
protocol CoordinatorFactory {
    func makeWalletCoordinator(navigationController: UINavigationController) -> WalletCoordinator
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator
}
