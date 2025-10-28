//
//  AddAccountViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WalletCore

/// 添加账户视图控制器
class AddAccountViewController: UIViewController {
    
    var wallet: Wallet!
    var mnemonic: String! // 添加助记词属性
    var onAccountAdded: ((WalletAccount) -> Void)?
    private let disposeBag = DisposeBag()
    private let derivationService: DerivationServiceProtocol = DerivationService()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let accountNameTextField = UITextField()
    private let addButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        title = "Add Account"
        view.backgroundColor = UIColor.systemBackground
        
        // Setup navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Setup title
        titleLabel.text = "Add New Account"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor.label
        titleLabel.textAlignment = .center
        
        // Setup description
        descriptionLabel.text = "Add a new account address to the current wallet"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = UIColor.secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Setup account name text field
        accountNameTextField.translatesAutoresizingMaskIntoConstraints = false
        accountNameTextField.placeholder = "Account Name (Optional)"
        accountNameTextField.borderStyle = .roundedRect
        accountNameTextField.backgroundColor = UIColor.systemGray6
        
        // Setup add button
        addButton.setTitle("Add Account", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = UIColor.systemBlue
        addButton.layer.cornerRadius = 8
        
        [titleLabel, descriptionLabel, accountNameTextField, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            // 滚动视图约束
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 内容视图约束
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 标题约束
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 描述约束
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 账户名称输入框约束
            accountNameTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            accountNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            accountNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            accountNameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // 添加按钮约束
            addButton.topAnchor.constraint(equalTo: accountNameTextField.bottomAnchor, constant: 30),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupBindings() {
        // 添加按钮
        addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addAccount()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    private func addAccount() {
        guard let mnemonic = mnemonic else {
            showErrorAlert("No mnemonic available")
            return
        }
        
        let accountName = accountNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Account"
        
        // 使用助记词派生新账户
        guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            showErrorAlert("Invalid mnemonic")
            return
        }
        
        // 获取当前钱包的账户数量，用于确定下一个索引
        let nextIndex = getNextAccountIndex()
        let derivationPath = "m/44'/60'/0'/0/\(nextIndex)"
        
        // 派生新账户的私钥和地址
        let privateKey = hdWallet.getKey(coin: CoinType.ethereum, derivationPath: derivationPath)
        guard let privateKeyObj = PrivateKey(data: privateKey.data) else {
            showErrorAlert("Failed to derive private key")
            return
        }
        
        let publicKey = privateKeyObj.getPublicKeySecp256k1(compressed: false)
        let address = AnyAddress(publicKey: publicKey, coin: CoinType.ethereum)
        
        // 创建新账户
        let newAccount = WalletAccount(
            id: "\(wallet.address)_\(nextIndex)",
            name: accountName,
            address: address.description,
            walletId: wallet.address,
            index: nextIndex,
            createdAt: Date()
        )
        
        onAccountAdded?(newAccount)
        dismiss(animated: true)
    }
    
    private func getNextAccountIndex() -> Int {
        // ✅ 从WalletManagerSingleton获取当前钱包
        guard let currentWallet = WalletManagerSingleton.shared.currentWalletSubject.value else {
            return 0 // 如果没有当前钱包，从0开始
        }
        
        // ✅ 通过通知机制获取该钱包的账户数量
        // 发送通知请求账户信息
        let accountCountKey = "accountCount_\(currentWallet.address)"
        let userInfo = ["walletAddress": currentWallet.address]
        
        // 使用UserDefaults作为临时存储来获取账户数量
        let accountCount = UserDefaults.standard.integer(forKey: accountCountKey)
        
        // 如果UserDefaults中没有记录，从0开始
        return accountCount
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - String Extension
extension String {
    static func random(length: Int) -> String {
        let letters = "abcdef0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
