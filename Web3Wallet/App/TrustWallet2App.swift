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
        
        // 设置窗口
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // 创建应用协调器
        let navigationController = UINavigationController()
        applicationCoordinator = ApplicationCoordinator(navigationController: navigationController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // 启动协调器
        applicationCoordinator?.start()
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // 应用进入前台时的处理
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // 应用进入后台时的处理
        Logger.info("Application entered background")
    }
}
