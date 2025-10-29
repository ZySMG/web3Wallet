//
//  trust_wallet2App.swift
//  trust_wallet2
//
//  Created by 张雨 on 2025/10/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var applicationCoordinator: ApplicationCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        guard !AppEnvironment.isRunningUnitTests else {
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = UIViewController()
            window?.makeKeyAndVisible()
            return true
        }
        
        if #available(iOS 13.0, *) {
            // Window setup handled in SceneDelegate for iOS 13+
        } else {
            let legacyWindow = UIWindow(frame: UIScreen.main.bounds)
            let navigationController = UINavigationController()
            let coordinator = ApplicationCoordinator(navigationController: navigationController)
            
            legacyWindow.rootViewController = navigationController
            legacyWindow.makeKeyAndVisible()
            
            window = legacyWindow
            applicationCoordinator = coordinator
            coordinator.start()
        }
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Handle app entering foreground
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Handle app entering background
        Logger.info("Application entered background")
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // No-op, provided for completeness
    }
}
