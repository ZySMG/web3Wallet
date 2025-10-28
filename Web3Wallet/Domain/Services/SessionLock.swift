//
//  SessionLock.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

/// Session lock service protocol
protocol SessionLockProtocol {
    /// Start session lock monitoring
    func startMonitoring()
    
    /// Stop session lock monitoring
    func stopMonitoring()
    
    /// Manual lock
    func lockSession()
    
    /// Unlock session
    func unlockSession()
    
    /// Reset lock timer
    func resetLockTimer()
    
    /// Session status observer
    var isLocked: BehaviorRelay<Bool> { get }
    
    /// Lock time setting
    var lockTimeout: TimeInterval { get set }
}

/// Session lock service implementation
class SessionLockService: SessionLockProtocol {
    
    private let session: WalletSession
    private let lockTimeoutSubject = BehaviorRelay<TimeInterval>(value: 300) // 默认5分钟
    private let isLockedSubject = BehaviorRelay<Bool>(value: true)
    
    private var lockTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let disposeBag = DisposeBag()
    
    var isLocked: BehaviorRelay<Bool> {
        return isLockedSubject
    }
    
    var lockTimeout: TimeInterval {
        get { return lockTimeoutSubject.value }
        set { lockTimeoutSubject.accept(newValue) }
    }
    
    init(session: WalletSession) {
        self.session = session
        setupBindings()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        setupAppStateObservers()
        resetLockTimer()
    }
    
    func stopMonitoring() {
        lockTimer?.invalidate()
        lockTimer = nil
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func lockSession() {
        Logger.info("Manually locking session")
        session.clearMemory()
        isLockedSubject.accept(true)
        stopLockTimer()
    }
    
    func unlockSession() {
        Logger.info("Session unlocked")
        isLockedSubject.accept(false)
        resetLockTimer()
    }
    
    func resetLockTimer() {
        stopLockTimer()
        startLockTimer()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen to lock timeout setting changes
        lockTimeoutSubject
            .subscribe(onNext: { [weak self] _ in
                self?.resetLockTimer()
            })
            .disposed(by: disposeBag)
    }
    
    private func setupAppStateObservers() {
        // Listen to app state changes
        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.handleAppDidEnterBackground()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.handleAppWillEnterForeground()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.handleAppDidBecomeActive()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.handleAppWillResignActive()
            })
            .disposed(by: disposeBag)
    }
    
    private func startLockTimer() {
        guard !isLockedSubject.value else { return }
        
        lockTimer = Timer.scheduledTimer(withTimeInterval: lockTimeout, repeats: false) { [weak self] _ in
            self?.handleLockTimeout()
        }
        
        Logger.info("Lock timer started: \(lockTimeout) seconds")
    }
    
    private func stopLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
        Logger.info("Lock timer stopped")
    }
    
    private func handleLockTimeout() {
        Logger.info("Lock timeout reached, locking session")
        lockSession()
    }
    
    private func handleAppDidEnterBackground() {
        Logger.info("App entered background")
        
        // Start background task
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SessionLock") { [weak self] in
            self?.lockSession()
            if self?.backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(self?.backgroundTask ?? .invalid)
                self?.backgroundTask = .invalid
            }
        }
        
        // If app goes to background, lock immediately (optional, can also set shorter timeout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.lockSession()
        }
    }
    
    private func handleAppWillEnterForeground() {
        Logger.info("App will enter foreground")
        
        // End background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func handleAppDidBecomeActive() {
        Logger.info("App became active")
        
        // When app becomes active, if locked, user needs to unlock again
        if isLockedSubject.value {
            Logger.info("App is active but session is locked")
        }
    }
    
    private func handleAppWillResignActive() {
        Logger.info("App will resign active")
        
        // When app is about to lose active state, can choose to lock immediately or reset timer
        // Here choose to reset timer, giving user some buffer time
        resetLockTimer()
    }
}

/// Session manager - unified management of wallet sessions and locking
class SessionManager {
    
    private let sessionLock: SessionLockProtocol
    private let session: WalletSession
    private let walletManager: WalletManager
    
    let isUnlocked: BehaviorRelay<Bool>
    
    init(sessionLock: SessionLockProtocol,
         session: WalletSession,
         walletManager: WalletManager) {
        self.sessionLock = sessionLock
        self.session = session
        self.walletManager = walletManager
        
        self.isUnlocked = BehaviorRelay<Bool>(value: false)
        
        setupBindings()
    }
    
    /// Unlock wallet
    func unlockWallet(walletId: String, password: String) -> Observable<Bool> {
        return walletManager.unlockWallet(walletId: walletId, password: password)
            .do(onNext: { [weak self] success in
                if success {
                    self?.sessionLock.unlockSession()
                    self?.isUnlocked.accept(true)
                }
            })
    }
    
    /// Lock wallet
    func lockWallet() {
        walletManager.lockWallet()
        sessionLock.lockSession()
        isUnlocked.accept(false)
    }
    
    /// Add new account
    func addAccount() -> Observable<Account> {
        return walletManager.addAccount()
    }
    
    /// Get current wallet accounts
    func getCurrentWalletAccounts() -> Observable<[Account]> {
        return walletManager.getCurrentWalletAccounts()
    }
    
    /// Switch wallet
    func switchWallet(walletId: String, password: String) -> Observable<Bool> {
        return walletManager.switchWallet(walletId: walletId, password: password)
            .do(onNext: { [weak self] success in
                if success {
                    self?.sessionLock.unlockSession()
                    self?.isUnlocked.accept(true)
                }
            })
    }
    
    private func setupBindings() {
        // Listen to session lock status
        sessionLock.isLocked
            .map { !$0 }
            .bind(to: isUnlocked)
            .disposed(by: DisposeBag())
    }
}
