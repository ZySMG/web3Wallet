//
//  ReceiveViewController.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// 接收页面视图控制器
class ReceiveViewController: UIViewController {
    
    var viewModel: ReceiveViewModel!
    var wallet: Wallet!
    private var disposeBag = DisposeBag() // ✅ 改为var，允许重新创建
    
    // MARK: - UI Elements
    private let addressLabel = UILabel()
    private let qrCodeImageView = UIImageView()
    private let copyButton = UIButton(type: .system)
    private let networkLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        loadCurrentWallet()
    }
    
    private func setupUI() {
        title = "receive.title".localized
        view.backgroundColor = UIColor.systemBackground
        
        // Configure network label
        networkLabel.font = UIFont.systemFont(ofSize: 14)
        networkLabel.textAlignment = .center
        networkLabel.textColor = UIColor.secondaryLabel
        networkLabel.backgroundColor = UIColor.systemGray5
        networkLabel.layer.cornerRadius = 6
        networkLabel.layer.masksToBounds = true
        
        // Configure address label
        addressLabel.font = UIFont.systemFont(ofSize: 16)
        addressLabel.textAlignment = .center
        addressLabel.textColor = UIColor.label
        addressLabel.numberOfLines = 0
        addressLabel.backgroundColor = UIColor.systemGray6
        addressLabel.layer.cornerRadius = 8
        addressLabel.layer.masksToBounds = true
        
        // 配置二维码图片
        qrCodeImageView.contentMode = .scaleAspectFit
        qrCodeImageView.backgroundColor = UIColor.white
        qrCodeImageView.layer.cornerRadius = 8
        qrCodeImageView.layer.masksToBounds = true
        
        // 配置复制按钮
        copyButton.setTitle("receive.copy_address".localized, for: .normal)
        copyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        copyButton.backgroundColor = UIColor.systemBlue
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.layer.cornerRadius = 12
        
        // Add subviews
        [networkLabel, addressLabel, qrCodeImageView, copyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            networkLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            networkLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            networkLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            networkLabel.heightAnchor.constraint(equalToConstant: 32),
            
            addressLabel.topAnchor.constraint(equalTo: networkLabel.bottomAnchor, constant: 16),
            addressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            addressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            addressLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            qrCodeImageView.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 32),
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeImageView.widthAnchor.constraint(equalToConstant: 200),
            qrCodeImageView.heightAnchor.constraint(equalToConstant: 200),
            
            copyButton.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 32),
            copyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            copyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            copyButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func bindViewModel() {
        // Bind button events
        copyButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.copyAddress()
            })
            .disposed(by: disposeBag)
        
        // Bind outputs
        viewModel.output.address
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.qrCodeImage
            .drive(qrCodeImageView.rx.image)
            .disposed(by: disposeBag)
        
        // Set network label text
        networkLabel.text = wallet?.network.name ?? "Unknown Network"
        
        // ✅ 监听钱包切换通知，更新Receive页面
        NotificationCenter.default.rx
            .notification(.walletSwitched)
            .compactMap { $0.object as? Wallet }
            .subscribe(onNext: { [weak self] newWallet in
                guard let self = self else { return }
                
                // ✅ 更新钱包和ViewModel
                self.wallet = newWallet
                self.viewModel = ReceiveViewModel(wallet: newWallet)
                
                // ✅ 重新创建disposeBag避免重复绑定
                self.disposeBag = DisposeBag()
                
                // ✅ 重新绑定UI
                self.bindViewModel()
                self.networkLabel.text = newWallet.network.name
                
                print("🔄 Receive page updated for wallet: \(newWallet.address)")
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Load Current Wallet
    
    private func loadCurrentWallet() {
        // ✅ 从Keychain加载当前活跃钱包
        let keychainStorage = KeychainStorageService()
        guard let walletString = keychainStorage.retrieve(key: "current_wallet"),
              let walletData = walletString.data(using: .utf8) else {
            return
        }
        
        do {
            let currentWallet = try JSONDecoder().decode(Wallet.self, from: walletData)
            
            // ✅ 更新钱包和ViewModel
            self.wallet = currentWallet
            self.viewModel = ReceiveViewModel(wallet: currentWallet)
            
            // ✅ 重新创建disposeBag避免重复绑定
            self.disposeBag = DisposeBag()
            
            // ✅ 重新绑定UI
            self.bindViewModel()
            self.networkLabel.text = currentWallet.network.name
            
            print("🔄 Receive page loaded current wallet: \(currentWallet.address)")
        } catch {
            print("Failed to load current wallet: \(error)")
        }
    }
    
    private func copyAddress() {
        guard let wallet = wallet else {
            showSuccessToast("No wallet available")
            return
        }
        
        UIPasteboard.general.string = wallet.address
        
        // Show success toast
        showSuccessToast("Address copied to clipboard")
        
        // Show risk warning after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let alert = UIAlertController(
                title: "Security Reminder",
                message: "⚠️ Please verify the copied address:\n\n• Ensure you copied the correct address\n• Wrong address may cause permanent fund loss\n• Recommend sending small test transaction first\n• Double-check each character",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "I Understand", style: .default))
            
            self?.present(alert, animated: true)
        }
    }
}

/// 接收页面视图模型
class ReceiveViewModel {
    
    struct Input {
        let copyTrigger = PublishRelay<Void>()
    }
    
    struct Output {
        let address: Driver<String>
        let qrCodeImage: Driver<UIImage?>
    }
    
    let input = Input()
    let output: Output
    
    private let wallet: Wallet
    
    init(wallet: Wallet) {
        self.wallet = wallet
        
        self.output = Output(
            address: Driver.just(wallet.address),
            qrCodeImage: Driver.just(QRCodeGenerator.generateWalletQRCode(address: wallet.address))
        )
    }
}
