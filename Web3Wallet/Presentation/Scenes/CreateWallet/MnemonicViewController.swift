//
//  MnemonicViewController.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Mnemonic display view controller
class MnemonicViewController: UIViewController {
    
    var viewModel: MnemonicViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let mnemonicLabel = UILabel()
    private let warningLabel = UILabel()
    private let copyButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        title = "onboarding.mnemonic.title".localized
        view.backgroundColor = UIColor.systemBackground
        
        // Configure title
        titleLabel.text = "onboarding.mnemonic.title".localized
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        titleLabel.numberOfLines = 0
        
        // Configure mnemonic label
        mnemonicLabel.font = UIFont.systemFont(ofSize: 16)
        mnemonicLabel.textAlignment = .center
        mnemonicLabel.textColor = UIColor.label
        mnemonicLabel.numberOfLines = 0
        mnemonicLabel.backgroundColor = UIColor.systemGray6
        mnemonicLabel.layer.cornerRadius = 8
        mnemonicLabel.layer.masksToBounds = true
        
        // Configure warning label
        warningLabel.text = "onboarding.mnemonic.warning".localized
        warningLabel.font = UIFont.systemFont(ofSize: 14)
        warningLabel.textAlignment = .center
        warningLabel.textColor = UIColor.systemRed
        warningLabel.numberOfLines = 0
        
        // Configure copy button
        copyButton.setTitle("onboarding.mnemonic.copy".localized, for: .normal)
        copyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        copyButton.backgroundColor = UIColor.systemGray5
        copyButton.setTitleColor(.label, for: .normal)
        copyButton.layer.cornerRadius = 8
        
        // Configure confirm button
        confirmButton.setTitle("onboarding.mnemonic.confirm".localized, for: .normal)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        confirmButton.backgroundColor = UIColor.systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        
        // Add subviews
        [titleLabel, mnemonicLabel, warningLabel, copyButton, confirmButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            mnemonicLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            mnemonicLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            mnemonicLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            mnemonicLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            warningLabel.topAnchor.constraint(equalTo: mnemonicLabel.bottomAnchor, constant: 16),
            warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            warningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            copyButton.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 32),
            copyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            copyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            copyButton.heightAnchor.constraint(equalToConstant: 44),
            
            confirmButton.topAnchor.constraint(equalTo: copyButton.bottomAnchor, constant: 16),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            confirmButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func bindViewModel() {
        // Bind button events
        copyButton.rx.tap
            .bind(to: viewModel.input.copyTrigger)
            .disposed(by: disposeBag)
        
        confirmButton.rx.tap
            .bind(to: viewModel.input.confirmTrigger)
            .disposed(by: disposeBag)
        
        // Bind outputs
        viewModel.output.mnemonic
            .drive(mnemonicLabel.rx.text)
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
        
        // Handle copy success toast
        viewModel.output.copySuccess
            .drive(onNext: { [weak self] _ in
                self?.showSuccessToast("Mnemonic copied to clipboard")
            })
            .disposed(by: disposeBag)
    }
}

/// Mnemonic view model
class MnemonicViewModel {
    
    struct Input {
        let copyTrigger = PublishRelay<Void>()
        let confirmTrigger = PublishRelay<Void>()
    }
    
    struct Output {
        let mnemonic: Driver<String>
        let walletCreated: Driver<Wallet>
        let error: Driver<Error>
        let copySuccess: Driver<Void>
    }
    
    let input = Input()
    let output: Output
    
    private let disposeBag = DisposeBag()
    private let generateWalletUseCase: GenerateMnemonicUseCaseProtocol
    private let mnemonic: String

    init(mnemonic: String, generateWalletUseCase: GenerateMnemonicUseCaseProtocol = GenerateMnemonicUseCase()) {
        self.mnemonic = mnemonic
        self.generateWalletUseCase = generateWalletUseCase
        
        let walletCreatedSubject = PublishRelay<Wallet>()
        let errorSubject = PublishRelay<Error>()
        let copySuccessSubject = PublishRelay<Void>()
        
        self.output = Output(
            mnemonic: Driver.just(mnemonic),
            walletCreated: walletCreatedSubject.asDriver(onErrorJustReturn: Wallet(address: "", network: Network.sepolia)),
            error: errorSubject.asDriver(onErrorJustReturn: WalletError.walletNotFound),
            copySuccess: copySuccessSubject.asDriver(onErrorDriveWith: .never())
        )
        
        // Bind confirm trigger
        input.confirmTrigger
            .flatMapLatest { [weak self] _ -> Observable<Wallet> in
                guard let self = self else { return Observable<Wallet>.empty() }
                return self.generateWalletUseCase.generateWallet(from: self.mnemonic, network: Network.sepolia)
            }
            .subscribe(onNext: { wallet in
                walletCreatedSubject.accept(wallet)
            }, onError: { error in
                errorSubject.accept(error)
            })
            .disposed(by: disposeBag)
        
        // Bind copy trigger
        input.copyTrigger
            .subscribe(onNext: { [weak self] _ in
                UIPasteboard.general.string = self?.mnemonic
                // Trigger copy success
                copySuccessSubject.accept(())
            })
            .disposed(by: disposeBag)
    }
}
