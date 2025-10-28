//
//  Toast.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit

/// Toast type
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: UIColor {
        switch self {
        case .success: return UIColor.systemGreen
        case .error: return UIColor.systemRed
        case .warning: return UIColor.systemOrange
        case .info: return UIColor.systemBlue
        }
    }
}

/// Toast manager
class ToastManager {
    
    static let shared = ToastManager()
    
    private var currentToast: ToastView?
    private let queue = DispatchQueue(label: "toast.queue", qos: .userInitiated)
    
    private init() {}
    
    /// Show Toast
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        queue.async {
            DispatchQueue.main.async {
                self.hideCurrentToast()
                self.showToast(message, type: type, duration: duration)
            }
        }
    }
    
    /// Show success Toast
    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .success, duration: duration)
    }
    
    /// Show error Toast
    func showError(_ message: String, duration: TimeInterval = 5.0) {
        show(message, type: .error, duration: duration)
    }
    
    /// Show warning Toast
    func showWarning(_ message: String, duration: TimeInterval = 4.0) {
        show(message, type: .warning, duration: duration)
    }
    
    /// Show info Toast
    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .info, duration: duration)
    }
    
    /// Hide current Toast
    func hide() {
        queue.async {
            DispatchQueue.main.async {
                self.hideCurrentToast()
            }
        }
    }
    
    private func showToast(_ message: String, type: ToastType, duration: TimeInterval) {
        guard let window = UIApplication.shared.windows.first else { return }
        
        let toast = ToastView(message: message, type: type)
        window.addSubview(toast)
        
        // Setup constraints
        toast.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 20),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -20),
            toast.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            toast.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        currentToast = toast
        
        // Show animation
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: -50)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            toast.alpha = 1
            toast.transform = .identity
        }
        
        // Auto hide
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.hideToast(toast)
        }
    }
    
    private func hideCurrentToast() {
        if let toast = currentToast {
            hideToast(toast)
        }
    }
    
    private func hideToast(_ toast: ToastView) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            toast.alpha = 0
            toast.transform = CGAffineTransform(translationX: 0, y: -50)
        } completion: { _ in
            toast.removeFromSuperview()
            if self.currentToast == toast {
                self.currentToast = nil
            }
        }
    }
}

/// Toast view
class ToastView: UIView {
    
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()
    private let type: ToastType
    
    init(message: String, type: ToastType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
        configure(message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.1
        
        // Configure icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: type.icon)
        iconImageView.tintColor = type.color
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)
        
        // Configure message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor.label
        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    private func configure(message: String) {
        messageLabel.text = message
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add border
        layer.borderWidth = 1
        layer.borderColor = type.color.withAlphaComponent(0.2).cgColor
    }
}

/// Toast extension
extension UIViewController {
    
    /// Show Toast
    func showToast(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        ToastManager.shared.show(message, type: type, duration: duration)
    }
    
    /// Show success Toast
    func showSuccessToast(_ message: String, duration: TimeInterval = 3.0) {
        ToastManager.shared.showSuccess(message, duration: duration)
    }
    
    /// Show error Toast
    func showErrorToast(_ message: String, duration: TimeInterval = 5.0) {
        ToastManager.shared.showError(message, duration: duration)
    }
    
    /// Show warning Toast
    func showWarningToast(_ message: String, duration: TimeInterval = 4.0) {
        ToastManager.shared.showWarning(message, duration: duration)
    }
    
    /// Show info Toast
    func showInfoToast(_ message: String, duration: TimeInterval = 3.0) {
        ToastManager.shared.showInfo(message, duration: duration)
    }
}
