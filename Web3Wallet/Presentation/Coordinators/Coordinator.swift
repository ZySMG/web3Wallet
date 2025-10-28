//
//  Coordinator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift

/// Coordinator protocol
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
    func finish()
}

/// Base coordinator class
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
    
    /// Add child coordinator
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    /// Remove child coordinator
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
    
    /// Remove all child coordinators
    func removeAllChildCoordinators() {
        childCoordinators.removeAll()
    }
}

/// Coordinator factory
protocol CoordinatorFactory {
    func makeWalletCoordinator(navigationController: UINavigationController) -> WalletCoordinator
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator
}
