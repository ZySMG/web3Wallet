//
//  WalletManagementViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Wallet management view controller
class WalletManagementViewController: UIViewController {
    
    var viewModel: WalletManagementViewModel!
    private let disposeBag = DisposeBag()
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let addWalletButton = UIButton(type: .system)
    // private let addAccountButton = UIButton(type: .system) // TODO: Commented out for later development
    private let clearAllWalletsButton = UIButton(type: .system)
    
    private var walletSections: [WalletSection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        title = "Wallet Management"
        view.backgroundColor = UIColor.systemBackground
        
        // Setup navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        
        // Setup table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AccountCell.self, forCellReuseIdentifier: "AccountCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = UIColor.systemBackground
        tableView.dataSource = self
        
        // Setup import wallet button
        addWalletButton.translatesAutoresizingMaskIntoConstraints = false
        addWalletButton.setTitle("Import Wallet", for: .normal)
        addWalletButton.setTitleColor(UIColor.white, for: .normal)
        addWalletButton.backgroundColor = UIColor.systemBlue
        addWalletButton.layer.cornerRadius = 8
        
        // TODO: Commented out for later development
        /*
        // Setup add account button
        addAccountButton.translatesAutoresizingMaskIntoConstraints = false
        addAccountButton.setTitle("Add Account", for: .normal)
        addAccountButton.setTitleColor(UIColor.white, for: .normal)
        addAccountButton.backgroundColor = UIColor.systemGreen
        addAccountButton.layer.cornerRadius = 8
        */
        
        // Setup clear all wallets button
        clearAllWalletsButton.translatesAutoresizingMaskIntoConstraints = false
        clearAllWalletsButton.setTitle("Clear All Wallets", for: .normal)
        clearAllWalletsButton.setTitleColor(UIColor.white, for: .normal)
        clearAllWalletsButton.backgroundColor = UIColor.systemRed
        clearAllWalletsButton.layer.cornerRadius = 8
        
        view.addSubview(tableView)
        view.addSubview(addWalletButton)
        // view.addSubview(addAccountButton) // TODO: Commented out for later development
        view.addSubview(clearAllWalletsButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            addWalletButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            addWalletButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addWalletButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addWalletButton.heightAnchor.constraint(equalToConstant: 50),
            
            // TODO: Commented out for later development
            /*
            addAccountButton.topAnchor.constraint(equalTo: addWalletButton.bottomAnchor, constant: 12),
            addAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addAccountButton.heightAnchor.constraint(equalToConstant: 50),
            */
            
            clearAllWalletsButton.topAnchor.constraint(equalTo: addWalletButton.bottomAnchor, constant: 12),
            clearAllWalletsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            clearAllWalletsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            clearAllWalletsButton.heightAnchor.constraint(equalToConstant: 50),
            clearAllWalletsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        // Bind wallet sections
        viewModel.output.walletSections
            .drive(onNext: { [weak self] sections in
                self?.updateTableView(with: sections)
            })
            .disposed(by: disposeBag)
        
        // Bind wallet selection using delegate
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.handleWalletSelection(at: indexPath)
            })
            .disposed(by: disposeBag)
        
        // Bind import wallet button
        addWalletButton.rx.tap
            .bind(to: viewModel.input.importWalletTrigger)
            .disposed(by: disposeBag)
        
        // TODO: Commented out for later development
        /*
        // Bind add account button
        addAccountButton.rx.tap
            .bind(to: viewModel.input.addAccountTrigger)
            .disposed(by: disposeBag)
        */
        
        // Bind clear all wallets button
        clearAllWalletsButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showClearAllWalletsConfirmation()
            })
            .disposed(by: disposeBag)
        
        // Bind navigation events
        viewModel.output.showImportWallet
            .drive(onNext: { [weak self] in
                self?.showImportWallet()
            })
            .disposed(by: disposeBag)
        
        // TODO: Commented out for later development
        /*
        viewModel.output.showAddAccount
            .drive(onNext: { [weak self] wallet in
                self?.showAddAccount(for: wallet)
            })
            .disposed(by: disposeBag)
        */
        
        viewModel.output.walletSwitched
            .drive(onNext: { [weak self] wallet in
                self?.switchToWallet(wallet)
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func showImportWallet() {
        let importVC = ImportWalletViewController()
        importVC.onWalletImported = { [weak self] wallet in
            self?.viewModel.addWallet(wallet)
        }
        
        let navController = UINavigationController(rootViewController: importVC)
        present(navController, animated: true)
    }
    
    // TODO: Commented out for later development
    /*
    private func showAddAccount(for wallet: Wallet) {
        let addAccountVC = AddAccountViewController()
        addAccountVC.wallet = wallet
        
        // ✅ 从Keychain获取助记词
        let keychainStorage = KeychainStorageService()
        if let mnemonic = keychainStorage.retrieve(key: "mnemonic_\(wallet.address)") {
            addAccountVC.mnemonic = mnemonic
        } else {
            // 如果没有找到助记词，显示错误
            let alert = UIAlertController(title: "Error", message: "Mnemonic not found for this wallet", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        addAccountVC.onAccountAdded = { [weak self] newAccount in
            self?.viewModel.addAccount(newAccount)
        }
        
        let navController = UINavigationController(rootViewController: addAccountVC)
        present(navController, animated: true)
    }
    */
    
    private func switchToWallet(_ wallet: Wallet) {
        dismiss(animated: true) {
            // Notify external wallet switch
            NotificationCenter.default.post(name: .walletSwitched, object: wallet)
        }
    }
    
    private func showDeleteAccountConfirmation(for account: WalletAccount) {
        // Check if this is the last wallet
        if walletSections.count <= 1 {
            let alert = UIAlertController(
                title: "Cannot Delete Account",
                message: "You cannot delete the last remaining account. Please create another wallet first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete this account? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteAccount(account)
        })
        
        present(alert, animated: true)
    }
    
    private func updateTableView(with sections: [WalletSection]) {
        self.walletSections = sections
        tableView.reloadData()
    }
    
    private func handleWalletSelection(at indexPath: IndexPath) {
        guard indexPath.section < walletSections.count,
              indexPath.row < walletSections[indexPath.section].accounts.count else {
            return
        }
        
        let account = walletSections[indexPath.section].accounts[indexPath.row]
        let wallet = walletSections[indexPath.section].wallet
        
        // Switch to the selected wallet
        viewModel.input.walletSelected.accept(wallet)
        
        // Deselect the row
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func showClearAllWalletsConfirmation() {
        let alert = UIAlertController(
            title: "Clear All Wallets",
            message: "This will permanently delete all wallets and accounts. This action cannot be undone. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.clearAllWallets()
        })
        
        present(alert, animated: true)
    }
    
    private func clearAllWallets() {
        // Clear all wallets from storage
        viewModel.clearAllWallets()
        
        // Show success message
        let alert = UIAlertController(
            title: "Success",
            message: "All wallets have been cleared. You will be redirected to the welcome screen.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigateToWelcomeScreen()
        })
        
        present(alert, animated: true)
    }
    
    private func navigateToWelcomeScreen() {
        // Dismiss current modal
        dismiss(animated: true) {
            // Post notification to navigate to welcome screen
            NotificationCenter.default.post(name: .navigateToWelcome, object: nil)
        }
    }
}

// MARK: - UITableViewDataSource
extension WalletManagementViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return walletSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < walletSections.count else { return 0 }
        return walletSections[section].accounts.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < walletSections.count else { return nil }
        return walletSections[section].walletName
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath) as! AccountCell
        
        guard indexPath.section < walletSections.count,
              indexPath.row < walletSections[indexPath.section].accounts.count else {
            return cell
        }
        
        let account = walletSections[indexPath.section].accounts[indexPath.row]
        let wallet = walletSections[indexPath.section].wallet
        
        cell.configure(with: account, wallet: wallet)
        cell.onDeleteTapped = { [weak self] in
            self?.showDeleteAccountConfirmation(for: account)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
}

/// Account cell for grouped display
class AccountCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let selectedIndicator = UILabel() // ✅ 添加选中状态指示器
    
    var onDeleteTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .gray
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = UIColor.label
        
        addressLabel.font = UIFont.systemFont(ofSize: 14)
        addressLabel.textColor = UIColor.secondaryLabel
        addressLabel.lineBreakMode = .byTruncatingMiddle
                
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(UIColor.systemRed, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // ✅ 配置选中状态指示器
        selectedIndicator.text = "✅"
        selectedIndicator.font = UIFont.systemFont(ofSize: 20)
        selectedIndicator.textAlignment = .center
        selectedIndicator.isHidden = true // 默认隐藏
        
        [nameLabel, addressLabel, deleteButton, selectedIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: selectedIndicator.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            
            addressLabel.leadingAnchor.constraint(equalTo: selectedIndicator.trailingAnchor, constant: 8),
            addressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // ✅ 选中状态指示器约束
            selectedIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            selectedIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectedIndicator.widthAnchor.constraint(equalToConstant: 30),
            selectedIndicator.heightAnchor.constraint(equalToConstant: 30),
            
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -8),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -8)
        ])
    }
    
    func configure(with account: WalletAccount, wallet: Wallet) {
        nameLabel.text = account.name
        addressLabel.text = account.address
        
        // ✅ 显示选中状态
        selectedIndicator.isHidden = !account.isSelected
    }
    
    @objc private func deleteButtonTapped() {
        onDeleteTapped?()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let walletSwitched = Notification.Name("walletSwitched")
    static let navigateToWelcome = Notification.Name("navigateToWelcome")
}
