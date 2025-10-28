//
//  ImportWalletViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// 导入钱包视图控制器
class ImportWalletViewController: UIViewController {
    
    var onWalletImported: ((Wallet) -> Void)?
    private let disposeBag = DisposeBag()
    
    // Use cases
    private let importWalletUseCase: ImportWalletUseCaseProtocol
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let mnemonicTextView = UITextView()
    private let importButton = UIButton(type: .system)
    
    init(importWalletUseCase: ImportWalletUseCaseProtocol = ImportWalletUseCase()) {
        self.importWalletUseCase = importWalletUseCase
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        title = "Import Wallet"
        view.backgroundColor = UIColor.systemBackground
        
        // Setup navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Setup title
        titleLabel.text = "Enter Mnemonic Phrase"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor.label
        titleLabel.textAlignment = .center
        
        // Setup mnemonic input
        mnemonicTextView.translatesAutoresizingMaskIntoConstraints = false
        mnemonicTextView.font = UIFont.systemFont(ofSize: 16)
        mnemonicTextView.backgroundColor = UIColor.systemGray6
        mnemonicTextView.layer.cornerRadius = 8
        mnemonicTextView.layer.borderWidth = 1.0
        mnemonicTextView.layer.borderColor = UIColor.systemGray4.cgColor
        mnemonicTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        mnemonicTextView.placeholder = "Enter 12 mnemonic words separated by spaces"
        
        // Setup import button
        importButton.setTitle("Import Wallet", for: .normal)
        importButton.setTitleColor(.white, for: .normal)
        importButton.backgroundColor = UIColor.systemBlue
        importButton.layer.cornerRadius = 8
        
        [titleLabel, mnemonicTextView, importButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Mnemonic input constraints
            mnemonicTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            mnemonicTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mnemonicTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mnemonicTextView.heightAnchor.constraint(equalToConstant: 120),
            
            // Import button constraints
            importButton.topAnchor.constraint(equalTo: mnemonicTextView.bottomAnchor, constant: 20),
            importButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            importButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            importButton.heightAnchor.constraint(equalToConstant: 50),
            importButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupBindings() {
        // Import button
        importButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.importWallet()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func cancelTapped() {
        // 智能判断返回方式
        if let navigationController = navigationController {
            // 如果是通过push进来的，使用pop
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                // 如果是通过present进来的，使用dismiss
                dismiss(animated: true)
            }
        } else {
            // 没有navigationController，直接dismiss
            dismiss(animated: true)
        }
    }
    
    private func importWallet() {
        guard let mnemonic = mnemonicTextView.text, !mnemonic.isEmpty else {
            showAlert(title: "Error", message: "Please enter mnemonic phrase")
            return
        }
        
        // Validate mnemonic
        let words = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
        if words.count != 12 {
            showAlert(title: "Error", message: "Mnemonic phrase must be 12 words")
            return
        }
        
        // Show loading
        importButton.isEnabled = false
        importButton.setTitle("Importing...", for: .normal)
        
        // Import wallet using real use case
        importWalletUseCase.importWallet(from: mnemonic, network: .sepolia)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] wallet in
                    self?.onWalletImported?(wallet)
                    self?.dismiss(animated: true)
                },
                onError: { [weak self] error in
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    self?.importButton.isEnabled = true
                    self?.importButton.setTitle("Import Wallet", for: .normal)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextView Placeholder Extension
extension UITextView {
    var placeholder: String? {
        get {
            return self.viewWithTag(100)?.accessibilityLabel
        }
        set {
            let placeholderLabel = UILabel()
            placeholderLabel.text = newValue
            placeholderLabel.font = self.font
            placeholderLabel.textColor = UIColor.placeholderText
            placeholderLabel.tag = 100
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(placeholderLabel)
            
            NSLayoutConstraint.activate([
                placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
                placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
            ])
            
            NotificationCenter.default.addObserver(
                forName: UITextView.textDidChangeNotification,
                object: self,
                queue: .main
            ) { _ in
                placeholderLabel.isHidden = !self.text.isEmpty
            }
        }
    }
}
