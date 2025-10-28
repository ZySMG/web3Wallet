//
//  NetworkSelectionViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Network selection view controller
class NetworkSelectionViewController: UIViewController {
    
    var onNetworkSelected: ((Network) -> Void)?
    
    // Method to set current network
    func setCurrentNetwork(_ network: Network) {
        currentNetwork = network
    }
    
    private let disposeBag = DisposeBag()
    private let tableView = UITableView()
    
    private let networks: [Network] = [
        Network.ethereumMainnet,
        Network.sepolia
    ]
    
    private var currentNetwork: Network = .sepolia // 默认当前网络为测试网
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        title = "选择网络"
        
        // Setup navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissViewController)
        )
        
        // Setup table view
        tableView.register(NetworkCell.self, forCellReuseIdentifier: "NetworkCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = UIColor.systemBackground
        
        // Add subviews
        view.addSubview(tableView)
        
        // Setup constraints
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        // Bind network list
        Observable.just(networks)
            .bind(to: tableView.rx.items(cellIdentifier: "NetworkCell", cellType: NetworkCell.self)) { [weak self] _, network, cell in
                let isSelected = network == self?.currentNetwork
                cell.configure(with: network, isSelected: isSelected)
            }
            .disposed(by: disposeBag)
        
        // Bind network selection
        tableView.rx.modelSelected(Network.self)
            .subscribe(onNext: { [weak self] network in
                self?.handleNetworkSelection(network)
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
    
    private func handleNetworkSelection(_ network: Network) {
        if network.isTestnet {
            // Testnet: normal switch
            onNetworkSelected?(network)
            dismiss(animated: true)
        } else {
            // Mainnet: show under development notice
            showUnderDevelopmentAlert()
        }
    }
    
    private func showUnderDevelopmentAlert() {
        let alert = UIAlertController(
            title: "Under Development",
            message: "Mainnet support is coming soon. Please stay on testnet for now.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

/// Network cell
class NetworkCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let chainIdLabel = UILabel()
    private let rpcLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    
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
        
        // Setup labels
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = UIColor.label
        
        chainIdLabel.font = UIFont.systemFont(ofSize: 14)
        chainIdLabel.textColor = UIColor.secondaryLabel
        
        rpcLabel.font = UIFont.systemFont(ofSize: 12)
        rpcLabel.textColor = UIColor.secondaryLabel
        rpcLabel.numberOfLines = 1
        
        // Setup checkmark icon
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = UIColor.systemBlue
        checkmarkImageView.contentMode = .scaleAspectFit
        
        [nameLabel, chainIdLabel, rpcLabel, checkmarkImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            chainIdLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chainIdLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
            rpcLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rpcLabel.topAnchor.constraint(equalTo: chainIdLabel.bottomAnchor, constant: 2),
            rpcLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),
            
            contentView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(with network: Network, isSelected: Bool = false) {
        nameLabel.text = network.name
        chainIdLabel.text = "Chain ID: \(network.chainId)"
        rpcLabel.text = network.rpcURL
        
        // Show selection state
        checkmarkImageView.isHidden = !isSelected
    }
}
