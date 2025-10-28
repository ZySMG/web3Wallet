//
//  TransactionListView.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// 交易列表视图
class TransactionListView: UIView {
    
    private let titleLabel = UILabel()
    let tableView = UITableView()
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        titleLabel.text = "wallet.history".localized
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor.label
        
        tableView.register(TransactionCell.self, forCellReuseIdentifier: "TransactionCell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        
        addSubview(titleLabel)
        addSubview(tableView)
        
        [titleLabel, tableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Reactive Extensions
extension Reactive where Base: TransactionListView {
    var transactions: Binder<[Transaction]> {
        return Binder(base) { view, transactions in
            // 清除之前的绑定
            view.disposeBag = DisposeBag()
            
            // 设置数据源
            Observable.just(transactions)
                .bind(to: view.tableView.rx.items(cellIdentifier: "TransactionCell", cellType: TransactionCell.self)) { _, transaction, cell in
                    cell.configure(with: transaction)
                }
                .disposed(by: view.disposeBag)
        }
    }
}

/// Transaction cell for displaying transaction information
class TransactionCell: UITableViewCell {
    
    private let containerView = UIView()
    private let directionIconView = UIView()
    private let directionLabel = UILabel()
    private let amountLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()
    private let addressLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .default
        backgroundColor = UIColor.systemBackground
        
        // Container view for better layout
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        
        // Direction icon view
        directionIconView.layer.cornerRadius = 20
        directionIconView.layer.masksToBounds = true
        
        // Direction label
        directionLabel.font = UIFont.boldSystemFont(ofSize: 16)
        directionLabel.textAlignment = .center
        directionLabel.textColor = UIColor.white
        
        // Amount label
        amountLabel.font = UIFont.boldSystemFont(ofSize: 16)
        amountLabel.textColor = UIColor.label
        
        // Time label
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor.secondaryLabel
        
        // Status label
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        
        // Address label (shortened)
        addressLabel.font = UIFont.systemFont(ofSize: 12)
        addressLabel.textColor = UIColor.secondaryLabel
        
        // Add subviews
        [containerView, directionIconView, directionLabel, amountLabel, timeLabel, statusLabel, addressLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        directionIconView.addSubview(directionLabel)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Direction icon
            directionIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            directionIconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            directionIconView.widthAnchor.constraint(equalToConstant: 40),
            directionIconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Direction label inside icon
            directionLabel.centerXAnchor.constraint(equalTo: directionIconView.centerXAnchor),
            directionLabel.centerYAnchor.constraint(equalTo: directionIconView.centerYAnchor),
            
            // Amount label
            amountLabel.leadingAnchor.constraint(equalTo: directionIconView.trailingAnchor, constant: 12),
            amountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            
            // Time label
            timeLabel.leadingAnchor.constraint(equalTo: directionIconView.trailingAnchor, constant: 12),
            timeLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            
            // Address label
            addressLabel.leadingAnchor.constraint(equalTo: directionIconView.trailingAnchor, constant: 12),
            addressLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Status label
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 60),
            statusLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with transaction: Transaction) {
        // Direction icon and label
        directionLabel.text = transaction.direction.icon
        directionIconView.backgroundColor = transaction.direction == .inbound ? UIColor.systemGreen : UIColor.systemRed
        
        // Amount
        amountLabel.text = transaction.formattedAmount
        
        // Time
        timeLabel.text = transaction.formattedTime
        
        // Status
        statusLabel.text = transaction.status.displayName
        switch transaction.status {
        case .success:
            statusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            statusLabel.textColor = UIColor.systemGreen
        case .pending:
            statusLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
            statusLabel.textColor = UIColor.systemOrange
        case .failed:
            statusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            statusLabel.textColor = UIColor.systemRed
        }
        
        // Address (show shortened version)
        let address = transaction.direction == .inbound ? transaction.from : transaction.to
        addressLabel.text = "\(address.prefix(6))...\(address.suffix(4))"
    }
}
