//
//  TransactionDetailViewController.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// 交易详情视图控制器
class TransactionDetailViewController: UIViewController {
    
    var viewModel: TransactionDetailViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let statusLabel = UILabel()
    private let amountLabel = UILabel()
    private let fromLabel = UILabel()
    private let toLabel = UILabel()
    private let hashLabel = UILabel()
    private let timeLabel = UILabel()
    private let explorerButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        title = "Transaction Details"
        view.backgroundColor = UIColor.systemBackground
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Configure status label
        statusLabel.font = UIFont.boldSystemFont(ofSize: 20)
        statusLabel.textAlignment = .center
        statusLabel.textColor = UIColor.label
        
        // Configure amount label
        amountLabel.font = UIFont.boldSystemFont(ofSize: 24)
        amountLabel.textAlignment = .center
        amountLabel.textColor = UIColor.label
        
        // Configure other labels
        [fromLabel, toLabel, hashLabel, timeLabel].forEach { label in
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = UIColor.label
            label.numberOfLines = 0
        }
        
        // Configure explorer button
        explorerButton.setTitle("View on Explorer", for: .normal)
        explorerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        explorerButton.backgroundColor = UIColor.systemBlue
        explorerButton.setTitleColor(.white, for: .normal)
        explorerButton.layer.cornerRadius = 12
        
        // Add subviews
        [statusLabel, amountLabel, fromLabel, toLabel, hashLabel, timeLabel, explorerButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            amountLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            amountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            fromLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 32),
            fromLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            fromLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            toLabel.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 16),
            toLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            toLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            hashLabel.topAnchor.constraint(equalTo: toLabel.bottomAnchor, constant: 16),
            hashLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            hashLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            timeLabel.topAnchor.constraint(equalTo: hashLabel.bottomAnchor, constant: 16),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            explorerButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 32),
            explorerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            explorerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            explorerButton.heightAnchor.constraint(equalToConstant: 56),
            explorerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func bindViewModel() {
        // Bind button events
        explorerButton.rx.tap
            .bind(to: viewModel.input.explorerTrigger)
            .disposed(by: disposeBag)
        
        // Bind outputs
        viewModel.output.status
            .drive(statusLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.amount
            .drive(amountLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.from
            .drive(fromLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.to
            .drive(toLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.hash
            .drive(hashLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.time
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)
        
        // Bind explorer action
        viewModel.output.openExplorer
            .drive(onNext: { [weak self] url in
                self?.openExplorer(url: url)
            })
            .disposed(by: disposeBag)
    }
    
    private func openExplorer(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Show error if can't open URL
            let alert = UIAlertController(title: "Error", message: "Cannot open explorer link", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

/// Transaction detail view model
class TransactionDetailViewModel {
    
    struct Input {
        let explorerTrigger = PublishRelay<Void>()
    }
    
    struct Output {
        let status: Driver<String>
        let amount: Driver<String>
        let from: Driver<String>
        let to: Driver<String>
        let hash: Driver<String>
        let time: Driver<String>
        let openExplorer: Driver<URL>
    }
    
    let input = Input()
    let output: Output
    
    private let transaction: Transaction
    private let disposeBag = DisposeBag()
    
    init(transaction: Transaction) {
        self.transaction = transaction
        
        // Create explorer URL driver
        let explorerURLDriver = input.explorerTrigger
            .map { [transaction] in
                return URL(string: transaction.explorerURL) ?? URL(string: "https://etherscan.io")!
            }
            .asDriver(onErrorJustReturn: URL(string: "https://etherscan.io")!)
        
        self.output = Output(
            status: Driver.just(transaction.status.displayName),
            amount: Driver.just(transaction.formattedAmount),
            from: Driver.just("From: \(transaction.from)"),
            to: Driver.just("To: \(transaction.to)"),
            hash: Driver.just("Hash: \(transaction.hash)"),
            time: Driver.just("Time: \(transaction.formattedTime)"),
            openExplorer: explorerURLDriver
        )
    }
}
