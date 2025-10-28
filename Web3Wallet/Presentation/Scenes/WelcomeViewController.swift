//
//  WelcomeViewController.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// 欢迎页面视图控制器
class WelcomeViewController: UIViewController {
    
    var viewModel: WelcomeViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let createWalletButton = UIButton(type: .system)
    private let importWalletButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // 配置标题
        titleLabel.text = "onboarding.welcome".localized
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        titleLabel.numberOfLines = 0
        
        // 配置副标题
        subtitleLabel.text = "onboarding.subtitle".localized
        subtitleLabel.font = UIFont.systemFont(ofSize: 18)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        // 配置创建钱包按钮
        createWalletButton.setTitle("onboarding.create_wallet".localized, for: .normal)
        createWalletButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createWalletButton.backgroundColor = UIColor.systemBlue
        createWalletButton.setTitleColor(.white, for: .normal)
        createWalletButton.layer.cornerRadius = 12
        
        // 配置导入钱包按钮
        importWalletButton.setTitle("onboarding.import_wallet".localized, for: .normal)
        importWalletButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        importWalletButton.backgroundColor = UIColor.systemGray5
        importWalletButton.setTitleColor(.label, for: .normal)
        importWalletButton.layer.cornerRadius = 12
        
        // 添加子视图
        [titleLabel, subtitleLabel, createWalletButton, importWalletButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            createWalletButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            createWalletButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            createWalletButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            createWalletButton.heightAnchor.constraint(equalToConstant: 56),
            
            importWalletButton.topAnchor.constraint(equalTo: createWalletButton.bottomAnchor, constant: 16),
            importWalletButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            importWalletButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            importWalletButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func bindViewModel() {
        // 绑定按钮事件
        createWalletButton.rx.tap
            .bind(to: viewModel.input.createWalletTrigger)
            .disposed(by: disposeBag)
        
        importWalletButton.rx.tap
            .bind(to: viewModel.input.importWalletTrigger)
            .disposed(by: disposeBag)
    }
}

/// 欢迎页面视图模型
class WelcomeViewModel {
    
    struct Input {
        let createWalletTrigger = PublishRelay<Void>()
        let importWalletTrigger = PublishRelay<Void>()
    }
    
    struct Output {
        let showCreateWallet: Driver<Void>
        let showImportWallet: Driver<Void>
    }
    
    let input = Input()
    let output: Output
    
    init() {
        self.output = Output(
            showCreateWallet: input.createWalletTrigger.asDriver(onErrorJustReturn: ()),
            showImportWallet: input.importWalletTrigger.asDriver(onErrorJustReturn: ())
        )
    }
}
