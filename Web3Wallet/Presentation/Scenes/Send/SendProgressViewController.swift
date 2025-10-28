//
//  SendProgressViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Send progress page view controller
class SendProgressViewController: UIViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var sendStatus: SendStatus = .sending
    private let onClose: () -> Void
    private let onViewTransaction: (String) -> Void
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let statusLabel = UILabel()
    private let progressIndicator = UIActivityIndicatorView(style: .large)
    private let successImageView = UIImageView()
    private let errorImageView = UIImageView()
    private let transactionHashLabel = UILabel()
    private let viewTransactionButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init(onClose: @escaping () -> Void, 
         onViewTransaction: @escaping (String) -> Void) {
        self.onClose = onClose
        self.onViewTransaction = onViewTransaction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updateUI(for: sendStatus)
    }
    
    // MARK: - Public Methods
    func updateStatus(_ status: SendStatus) {
        sendStatus = status
        updateUI(for: status)
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Configure container view
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.1
        
        // Configure status label
        statusLabel.font = UIFont.boldSystemFont(ofSize: 20)
        statusLabel.textColor = UIColor.label
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        
        // Configure progress indicator
        progressIndicator.color = UIColor.systemBlue
        progressIndicator.hidesWhenStopped = true
        
        // Configure success image view
        successImageView.image = UIImage(systemName: "checkmark.circle.fill")
        successImageView.tintColor = UIColor.systemGreen
        successImageView.contentMode = .scaleAspectFit
        successImageView.isHidden = true
        
        // Configure error image view
        errorImageView.image = UIImage(systemName: "xmark.circle.fill")
        errorImageView.tintColor = UIColor.systemRed
        errorImageView.contentMode = .scaleAspectFit
        errorImageView.isHidden = true
        
        // Configure transaction hash label
        transactionHashLabel.font = UIFont.systemFont(ofSize: 14)
        transactionHashLabel.textColor = UIColor.secondaryLabel
        transactionHashLabel.textAlignment = .center
        transactionHashLabel.numberOfLines = 0
        transactionHashLabel.isHidden = true
        
        // Configure view transaction button
        viewTransactionButton.setTitle("View Transaction", for: .normal)
        viewTransactionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        viewTransactionButton.backgroundColor = UIColor.systemBlue
        viewTransactionButton.setTitleColor(.white, for: .normal)
        viewTransactionButton.layer.cornerRadius = 12
        viewTransactionButton.isHidden = true
        
        // Configure close button
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        closeButton.backgroundColor = UIColor.systemGray5
        closeButton.setTitleColor(.label, for: .normal)
        closeButton.layer.cornerRadius = 12
        
        // Add subviews
        [containerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        [statusLabel, progressIndicator, successImageView, errorImageView, 
         transactionHashLabel, viewTransactionButton, closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Progress indicator
            progressIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            progressIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressIndicator.widthAnchor.constraint(equalToConstant: 50),
            progressIndicator.heightAnchor.constraint(equalToConstant: 50),
            
            // Success image view
            successImageView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            successImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            successImageView.widthAnchor.constraint(equalToConstant: 50),
            successImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Error image view
            errorImageView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            errorImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            errorImageView.widthAnchor.constraint(equalToConstant: 50),
            errorImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Transaction hash label
            transactionHashLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 24),
            transactionHashLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            transactionHashLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // View transaction button
            viewTransactionButton.topAnchor.constraint(equalTo: transactionHashLabel.bottomAnchor, constant: 24),
            viewTransactionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            viewTransactionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            viewTransactionButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: viewTransactionButton.bottomAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32)
        ])
    }
    
    private func setupBindings() {
        // View transaction button
        viewTransactionButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self,
                      let txHash = self.sendStatus.transactionHash else { return }
                self.onViewTransaction(txHash)
            })
            .disposed(by: disposeBag)
        
        // Close button
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onClose()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateUI(for status: SendStatus) {
        DispatchQueue.main.async {
            // Update status label
            self.statusLabel.text = status.displayText
            
            // Update progress indicator
            switch status {
            case .sending:
                self.progressIndicator.startAnimating()
                self.progressIndicator.isHidden = false
                self.successImageView.isHidden = true
                self.errorImageView.isHidden = true
            case .success:
                self.progressIndicator.stopAnimating()
                self.progressIndicator.isHidden = true
                self.successImageView.isHidden = false
                self.errorImageView.isHidden = true
            case .failed:
                self.progressIndicator.stopAnimating()
                self.progressIndicator.isHidden = true
                self.successImageView.isHidden = true
                self.errorImageView.isHidden = false
            }
            
            // Update transaction hash label
            if let txHash = status.transactionHash {
                self.transactionHashLabel.text = "Transaction Hash:\n\(txHash)"
                self.transactionHashLabel.isHidden = false
            } else {
                self.transactionHashLabel.isHidden = true
            }
            
            // Update buttons visibility
            self.viewTransactionButton.isHidden = !status.canViewTransaction
            
            // Update close button
            self.closeButton.isHidden = false
        }
    }
}
