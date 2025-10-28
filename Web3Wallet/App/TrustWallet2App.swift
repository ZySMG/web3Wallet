//
//  trust_wallet2App.swift
//  trust_wallet2
//
//  Created by 张雨 on 2025/10/26.
//

import UIKit
import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var applicationCoordinator: ApplicationCoordinator?
    private let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Setup window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create application coordinator
        let navigationController = UINavigationController()
        applicationCoordinator = ApplicationCoordinator(navigationController: navigationController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // Start coordinator
        applicationCoordinator?.start()
        
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
}
