//
//  CreateWalletViewController.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// 创建钱包视图控制器
class CreateWalletViewController: UIViewController {
    
    var viewModel: CreateWalletViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let createButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        title = "wallet.create".localized
        view.backgroundColor = UIColor.systemBackground
        
        // 配置标题
        titleLabel.text = "onboarding.mnemonic.title".localized
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        titleLabel.numberOfLines = 0
        
        // 配置副标题
        subtitleLabel.text = "onboarding.mnemonic.subtitle".localized
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        // 配置创建按钮
        createButton.setTitle("wallet.create".localized, for: .normal)
        createButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createButton.backgroundColor = UIColor.systemBlue
        createButton.setTitleColor(.white, for: .normal)
        createButton.layer.cornerRadius = 12
        
        // 添加子视图
        [titleLabel, subtitleLabel, createButton].forEach {
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
            
            createButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            createButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func bindViewModel() {
        // 绑定按钮事件
        createButton.rx.tap
            .bind(to: viewModel.input.createTrigger)
            .disposed(by: disposeBag)
        
        // 绑定输出
        viewModel.output.showMnemonic
            .drive(onNext: { [weak self] mnemonic in
                // 这里会由协调器处理导航
            })
            .disposed(by: disposeBag)
        
        viewModel.output.walletCreated
            .drive(onNext: { [weak self] wallet in
                // 这里会由协调器处理导航
            })
            .disposed(by: disposeBag)
        
        viewModel.output.error
            .drive(onNext: { [weak self] error in
                self?.showErrorToast(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}

/// 创建钱包视图模型
class CreateWalletViewModel {
    
    struct Input {
        let createTrigger = PublishRelay<Void>()
    }
    
    struct Output {
        let showMnemonic: Driver<String>
        let walletCreated: Driver<Wallet>
        let error: Driver<Error>
    }
    
    let input = Input()
    let output: Output
    
    private let disposeBag = DisposeBag()
    private let generateMnemonicUseCase: GenerateMnemonicUseCaseProtocol
    
    init() {
        self.generateMnemonicUseCase = GenerateMnemonicUseCase()
        
        let showMnemonicSubject = PublishRelay<String>()
        let walletCreatedSubject = PublishRelay<Wallet>()
        let errorSubject = PublishRelay<Error>()
        
        self.output = Output(
            showMnemonic: showMnemonicSubject.asDriver(onErrorJustReturn: ""),
            walletCreated: walletCreatedSubject.asDriver(onErrorJustReturn: Wallet(address: "", network: Network.sepolia)),
            error: errorSubject.asDriver(onErrorJustReturn: WalletError.walletNotFound)
        )
        
        // 绑定创建触发
        input.createTrigger
            .flatMapLatest { [weak self] _ in
                self?.generateMnemonicUseCase.generateMnemonic() ?? Observable.empty()
            }
            .subscribe(onNext: { mnemonic in
                showMnemonicSubject.accept(mnemonic)
            }, onError: { error in
                errorSubject.accept(error)
            })
            .disposed(by: disposeBag)
    }
}
