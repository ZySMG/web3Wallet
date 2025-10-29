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

/// Create wallet view controller
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
        
        // Configure title
        titleLabel.text = "onboarding.mnemonic.title".localized
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        titleLabel.numberOfLines = 0
        
        // Configure subtitle
        subtitleLabel.text = "onboarding.mnemonic.subtitle".localized
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        // Configure create button
        createButton.setTitle("wallet.create".localized, for: .normal)
        createButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createButton.backgroundColor = UIColor.systemBlue
        createButton.setTitleColor(.white, for: .normal)
        createButton.layer.cornerRadius = 12
        
        // Add subviews
        [titleLabel, subtitleLabel, createButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Setup constraints
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
        // Bind button events
        createButton.rx.tap
            .bind(to: viewModel.input.createTrigger)
            .disposed(by: disposeBag)
        
        // Bind outputs
        viewModel.output.showMnemonic
            .drive(onNext: { [weak self] mnemonic in
                // Navigation will be handled by coordinator
            })
            .disposed(by: disposeBag)
        
        viewModel.output.walletCreated
            .drive(onNext: { [weak self] wallet in
                // Navigation will be handled by coordinator
            })
            .disposed(by: disposeBag)
        
        viewModel.output.error
            .drive(onNext: { [weak self] error in
                self?.showErrorToast(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}

/// Create wallet view model
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
    
    init(generateMnemonicUseCase: GenerateMnemonicUseCaseProtocol = GenerateMnemonicUseCase()) {
        self.generateMnemonicUseCase = generateMnemonicUseCase
        
        let showMnemonicSubject = PublishRelay<String>()
        let walletCreatedSubject = PublishRelay<Wallet>()
        let errorSubject = PublishRelay<Error>()
        
        self.output = Output(
            showMnemonic: showMnemonicSubject.asDriver(onErrorJustReturn: ""),
            walletCreated: walletCreatedSubject.asDriver(onErrorJustReturn: Wallet(address: "", network: Network.sepolia)),
            error: errorSubject.asDriver(onErrorJustReturn: WalletError.walletNotFound)
        )
        
        // Bind create trigger
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
