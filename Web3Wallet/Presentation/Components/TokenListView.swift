//
//  TokenListView.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Token list view
class TokenListView: UIView {
    
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
        backgroundColor = UIColor.clear
        
        // Setup title
        titleLabel.text = "Token"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor.white
        
        // Setup table view
        tableView.register(TokenCell.self, forCellReuseIdentifier: "TokenCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
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
extension Reactive where Base: TokenListView {
    var balances: Binder<[Balance]> {
        return Binder(base) { view, balances in
            // Clear previous bindings
            view.disposeBag = DisposeBag()
            
            // Setup data source
            Observable.just(balances)
                .bind(to: view.tableView.rx.items(cellIdentifier: "TokenCell", cellType: TokenCell.self)) { _, balance, cell in
                    cell.configure(with: balance)
                }
                .disposed(by: view.disposeBag)
        }
    }
}

/// Token cell
class TokenCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let balanceLabel = UILabel()
    private let usdValueLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.clear
        
        // Setup background
        contentView.backgroundColor = UIColor.systemGray6
        contentView.layer.cornerRadius = 12
        
        // Setup labels
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = UIColor.label
        
        balanceLabel.font = UIFont.systemFont(ofSize: 16)
        balanceLabel.textColor = UIColor.label
        balanceLabel.textAlignment = .right
        
        usdValueLabel.font = UIFont.systemFont(ofSize: 14)
        usdValueLabel.textColor = UIColor.secondaryLabel
        usdValueLabel.textAlignment = .right
        
        [nameLabel, balanceLabel, usdValueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),
            
            balanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            balanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),
            balanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            
            usdValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            usdValueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 8),
            usdValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            
            contentView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configure(with balance: Balance) {
        nameLabel.text = balance.currency.symbol
        balanceLabel.text = balance.formattedAmount
        usdValueLabel.text = balance.formattedUSDValue
    }
}
