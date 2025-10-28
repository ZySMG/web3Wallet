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

/// 会话锁定服务协议
protocol SessionLockProtocol {
    /// 开始会话锁定监控
    func startMonitoring()
    
    /// 停止会话锁定监控
    func stopMonitoring()
    
    /// 手动锁定
    func lockSession()
    
    /// 解锁会话
    func unlockSession()
    
    /// 重置锁定计时器
    func resetLockTimer()
    
    /// 会话状态观察者
    var isLocked: BehaviorRelay<Bool> { get }
    
    /// 锁定时间设置
    var lockTimeout: TimeInterval { get set }
}

/// 会话锁定服务实现
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
        // 监听锁定超时设置变化
        lockTimeoutSubject
            .subscribe(onNext: { [weak self] _ in
                self?.resetLockTimer()
            })
            .disposed(by: disposeBag)
    }
    
    private func setupAppStateObservers() {
        // 监听应用状态变化
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
        
        // 开始后台任务
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SessionLock") { [weak self] in
            self?.lockSession()
            if self?.backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(self?.backgroundTask ?? .invalid)
                self?.backgroundTask = .invalid
            }
        }
        
        // 如果应用进入后台，立即锁定（可选，也可以设置较短的超时时间）
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.lockSession()
        }
    }
    
    private func handleAppWillEnterForeground() {
        Logger.info("App will enter foreground")
        
        // 结束后台任务
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func handleAppDidBecomeActive() {
        Logger.info("App became active")
        
        // 应用变为活跃时，如果已锁定，需要用户重新解锁
        if isLockedSubject.value {
            Logger.info("App is active but session is locked")
        }
    }
    
    private func handleAppWillResignActive() {
        Logger.info("App will resign active")
        
        // 应用即将失去活跃状态时，可以选择立即锁定或重置计时器
        // 这里选择重置计时器，给用户一些缓冲时间
        resetLockTimer()
    }
}

/// 会话管理器 - 统一管理钱包会话和锁定
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
    
    /// 解锁钱包
    func unlockWallet(walletId: String, password: String) -> Observable<Bool> {
        return walletManager.unlockWallet(walletId: walletId, password: password)
            .do(onNext: { [weak self] success in
                if success {
                    self?.sessionLock.unlockSession()
                    self?.isUnlocked.accept(true)
                }
            })
    }
    
    /// 锁定钱包
    func lockWallet() {
        walletManager.lockWallet()
        sessionLock.lockSession()
        isUnlocked.accept(false)
    }
    
    /// 添加新账户
    func addAccount() -> Observable<Account> {
        return walletManager.addAccount()
    }
    
    /// 获取当前钱包账户
    func getCurrentWalletAccounts() -> Observable<[Account]> {
        return walletManager.getCurrentWalletAccounts()
    }
    
    /// 切换钱包
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
        // 监听会话锁定状态
        sessionLock.isLocked
            .map { !$0 }
            .bind(to: isUnlocked)
            .disposed(by: DisposeBag())
    }
}
