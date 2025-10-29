//
//  SceneDelegate.swift
//  Web3Wallet
//
//  Created by Codex on 2025/01/17.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private var applicationCoordinator: ApplicationCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard !AppEnvironment.isRunningUnitTests else {
            if let windowScene = scene as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIViewController()
                window.makeKeyAndVisible()
                self.window = window
            }
            return
        }
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()
        let coordinator = ApplicationCoordinator(navigationController: navigationController)
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        self.window = window
        self.applicationCoordinator = coordinator
        coordinator.start()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        Logger.info("Application entered background")
    }
}
