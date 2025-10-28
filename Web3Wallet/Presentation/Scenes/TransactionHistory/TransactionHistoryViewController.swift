//
//  TransactionHistoryViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Transaction history view controller
class TransactionHistoryViewController: UIViewController {
    
    var viewModel: TransactionHistoryViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupWalletSwitchingListener()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        title = "Transaction History"
        
        // Setup navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Setup table view
        tableView.register(TransactionCell.self, forCellReuseIdentifier: "TransactionCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = UIColor.systemBackground
        tableView.refreshControl = refreshControl
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        // Setup empty state view
        emptyStateView.backgroundColor = UIColor.systemBackground
        emptyStateLabel.text = "No Transaction History\nYour transaction records will appear here"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = UIColor.secondaryLabel
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.numberOfLines = 0
        
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -20)
        ])
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        
        // Setup constraints
        [tableView, emptyStateView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func bindViewModel() {
        // Bind refresh
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.input.refreshTrigger)
            .disposed(by: disposeBag)
        
        // Bind transaction list
        viewModel.output.transactions
            .drive(tableView.rx.items(cellIdentifier: "TransactionCell", cellType: TransactionCell.self)) { _, transaction, cell in
                cell.configure(with: transaction)
            }
            .disposed(by: disposeBag)
        
        // Bind loading state
        viewModel.output.isLoading
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        // Bind empty state
        viewModel.output.transactions
            .map { !$0.isEmpty } // 当有交易时隐藏空状态，当没有交易时显示空状态
            .drive(emptyStateView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // Bind errors
        viewModel.output.error
            .drive(onNext: { [weak self] error in
                self?.showErrorAlert(error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        // Bind transaction selection
        tableView.rx.modelSelected(Transaction.self)
            .do(onNext: { [weak self] _ in
                // ✅ Cancel cell selection state
                if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                    self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
                }
            })
            .bind(to: viewModel.input.transactionSelected)
            .disposed(by: disposeBag)
        
        // Bind transaction detail display
        viewModel.output.showTransactionDetail
            .drive(onNext: { [weak self] transaction in
                self?.showTransactionDetail(transaction: transaction)
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showTransactionDetail(transaction: Transaction) {
        let detailVC = TransactionDetailViewController()
        let detailVM = TransactionDetailViewModel(transaction: transaction)
        detailVC.viewModel = detailVM
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Wallet Switching Listener
    
    private func setupWalletSwitchingListener() {
        NotificationCenter.default.rx
            .notification(.walletSwitched)
            .compactMap { $0.object as? Wallet }
            .subscribe(onNext: { [weak self] newWallet in
                guard let self = self else { return }
                
                // ✅ Update ViewModel wallet
                self.viewModel.updateWallet(newWallet)
                
                print("🔄 Transaction history page updated for wallet: \(newWallet.address)")
            })
            .disposed(by: disposeBag)
    }
}


