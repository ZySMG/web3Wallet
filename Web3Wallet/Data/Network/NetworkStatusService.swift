//
//  NetworkStatusService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import Network
import RxSwift
import RxCocoa

/// Network status monitoring service
class NetworkStatusService {
    
    static let shared = NetworkStatusService()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // Observable for network status
    let isConnectedSubject = BehaviorRelay<Bool>(value: true)
    var isConnected: Observable<Bool> {
        return isConnectedSubject.asObservable()
    }
    
    // Observable for airplane mode detection
    let isAirplaneModeSubject = BehaviorRelay<Bool>(value: false)
    var isAirplaneMode: Observable<Bool> {
        return isAirplaneModeSubject.asObservable()
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let isConnected = path.status == .satisfied
                let isAirplaneMode = self.detectAirplaneMode(path: path)
                
                self.isConnectedSubject.accept(isConnected)
                self.isAirplaneModeSubject.accept(isAirplaneMode)
                
                // Log network status changes
                if isAirplaneMode {
                    print("✈️ Airplane mode detected - Network unavailable")
                } else if !isConnected {
                    print("📶 Network disconnected")
                } else {
                    print("📶 Network connected")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func detectAirplaneMode(path: NWPath) -> Bool {
        // Airplane mode is detected when:
        // 1. No interfaces are available (wifi, cellular, ethernet)
        // 2. Status is unsatisfied
        // 3. All interfaces are unavailable
        
        let hasWifi = path.usesInterfaceType(.wifi)
        let hasCellular = path.usesInterfaceType(.cellular)
        let hasEthernet = path.usesInterfaceType(.wiredEthernet)
        let hasOther = path.usesInterfaceType(.other)
        
        let hasAnyInterface = hasWifi || hasCellular || hasEthernet || hasOther
        let isUnsatisfied = path.status == .unsatisfied
        
        // Airplane mode: unsatisfied status with no available interfaces
        return isUnsatisfied && !hasAnyInterface
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Network Status Extensions

extension NetworkStatusService {
    
    /// Show airplane mode alert
    func showAirplaneModeAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Airplane Mode Detected",
            message: "Please turn off airplane mode to use wallet features. Some functions may not work properly without internet connection:\n\n• Balance updates\n• Transaction sending\n• Transaction history\n• Price information",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Add settings action if available
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                UIApplication.shared.open(settingsUrl)
            })
        }
        
        viewController.present(alert, animated: true)
    }
    
    /// Show network disconnected alert
    func showNetworkDisconnectedAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "No Internet Connection",
            message: "Please check your internet connection. Some features may not work properly:\n\n• Balance updates\n• Transaction sending\n• Transaction history\n• Price information",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
    }
}
