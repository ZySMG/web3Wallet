//
//  SendViewController.swift
//  trust_wallet2
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - Notification Names
extension Notification.Name {
    static let showTransactionHistory = Notification.Name("showTransactionHistory")
}

// MARK: - String Extension
extension String {
    static func randomString(length: Int) -> String {
        let letters = "abcdef0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

/// Send page view controller
class SendViewController: UIViewController {
    
    var viewModel: SendViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let networkLabel = UILabel()
    private let currencyLabel = UILabel()
    private let toAddressTextField = UITextField()
    private let addressValidationLabel = UILabel()
    private let amountTextField = UITextField()
    private let balanceLabel = UILabel()
    private let gasPriceLabel = UILabel()
    private let gasLimitLabel = UILabel()
    private let feeLabel = UILabel()
    private let totalCostLabel = UILabel()
    private let insufficientBalanceLabel = UILabel()
    private let transactionDetailsLabel = UILabel()
    private let gasProgressView = UIProgressView(progressViewStyle: .default)
    private let gasCountdownLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    
    // MARK: - Gas Countdown Properties
    private var gasCountdownTimer: Timer?
    private var gasCountdownSeconds = 5
    private var progressViewController: SendProgressViewController?
    
    // MARK: - Circular Progress View
    private let circularProgressView = CircularProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupKeyboardHandling()
        setupWalletSwitchingListener()
    }
    
    private func setupUI() {
        title = "Send Transaction"
        view.backgroundColor = UIColor.systemBackground
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure network label
        networkLabel.font = UIFont.systemFont(ofSize: 14)
        networkLabel.textAlignment = .center
        networkLabel.textColor = UIColor.secondaryLabel
        networkLabel.backgroundColor = UIColor.systemGray5
        networkLabel.layer.cornerRadius = 6
        networkLabel.layer.masksToBounds = true
        
        // Configure currency label
        currencyLabel.font = UIFont.boldSystemFont(ofSize: 18)
        currencyLabel.textAlignment = .center
        currencyLabel.textColor = UIColor.label
        currencyLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        currencyLabel.layer.cornerRadius = 8
        currencyLabel.layer.masksToBounds = true
        
        // Configure recipient address input field
        toAddressTextField.placeholder = "Recipient Address (0x...)"
        toAddressTextField.borderStyle = .roundedRect
        toAddressTextField.font = UIFont.systemFont(ofSize: 16)
        toAddressTextField.autocapitalizationType = .none
        toAddressTextField.autocorrectionType = .no
        
        // Configure address validation label
        addressValidationLabel.font = UIFont.systemFont(ofSize: 12)
        addressValidationLabel.textColor = UIColor.systemRed
        addressValidationLabel.numberOfLines = 0
        
        // Configure amount input field
        amountTextField.placeholder = "Amount (\(viewModel.selectedCurrency.symbol))"
        amountTextField.borderStyle = .roundedRect
        amountTextField.font = UIFont.systemFont(ofSize: 16)
        amountTextField.keyboardType = .decimalPad
        
        // Configure balance label
        balanceLabel.font = UIFont.systemFont(ofSize: 14)
        balanceLabel.textColor = UIColor.secondaryLabel
        balanceLabel.text = "Balance: 0.000000 ETH"
        
        // Configure gas price label
        gasPriceLabel.font = UIFont.systemFont(ofSize: 14)
        gasPriceLabel.textColor = UIColor.secondaryLabel
        gasPriceLabel.text = "Gas Price: --"
        
        // Configure gas limit label
        gasLimitLabel.font = UIFont.systemFont(ofSize: 14)
        gasLimitLabel.textColor = UIColor.secondaryLabel
        gasLimitLabel.text = "Gas Limit: --"
        
        // Configure fee label
        feeLabel.font = UIFont.systemFont(ofSize: 14)
        feeLabel.textColor = UIColor.secondaryLabel
        feeLabel.text = "Network Fee: --"
        
        // Configure total cost label
        totalCostLabel.font = UIFont.boldSystemFont(ofSize: 16)
        totalCostLabel.textColor = UIColor.label
        totalCostLabel.text = "Total Cost: --"
        
        // Configure insufficient balance label
        insufficientBalanceLabel.font = UIFont.systemFont(ofSize: 14)
        insufficientBalanceLabel.textColor = UIColor.systemRed
        insufficientBalanceLabel.text = ""
        insufficientBalanceLabel.numberOfLines = 0
        
        // Configure transaction details label
        transactionDetailsLabel.font = UIFont.boldSystemFont(ofSize: 16)
        transactionDetailsLabel.textColor = UIColor.label
        transactionDetailsLabel.text = "Transaction Details"
        transactionDetailsLabel.textAlignment = .left
        
        // Configure circular progress view
        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure gas countdown label
        gasCountdownLabel.font = UIFont.systemFont(ofSize: 12)
        gasCountdownLabel.textColor = UIColor.secondaryLabel
        gasCountdownLabel.textAlignment = .center
        gasCountdownLabel.text = "Gas will refresh in 5s"
        gasCountdownLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure send button
        sendButton.setTitle("Send Transaction", for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 12
        sendButton.isEnabled = false
        
        // Configure disabled state
        sendButton.setTitleColor(.white, for: .disabled)
        sendButton.backgroundColor = UIColor.systemGray4
        
        // Add all subviews
        [networkLabel, currencyLabel, toAddressTextField, addressValidationLabel, amountTextField, balanceLabel,
         gasPriceLabel, gasLimitLabel, feeLabel, totalCostLabel, insufficientBalanceLabel, transactionDetailsLabel, circularProgressView, gasCountdownLabel, sendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Network label
            networkLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            networkLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            networkLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            networkLabel.heightAnchor.constraint(equalToConstant: 32),
            
            // Currency label
            currencyLabel.topAnchor.constraint(equalTo: networkLabel.bottomAnchor, constant: 12),
            currencyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            currencyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            currencyLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // Recipient address field
            toAddressTextField.topAnchor.constraint(equalTo: currencyLabel.bottomAnchor, constant: 20),
            toAddressTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            toAddressTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            toAddressTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Address validation label
            addressValidationLabel.topAnchor.constraint(equalTo: toAddressTextField.bottomAnchor, constant: 4),
            addressValidationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addressValidationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Amount field
            amountTextField.topAnchor.constraint(equalTo: addressValidationLabel.bottomAnchor, constant: 16),
            amountTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            amountTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            amountTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Balance label
            balanceLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 8),
            balanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            balanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Transaction details label
            transactionDetailsLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 16),
            transactionDetailsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            transactionDetailsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Circular progress view
            circularProgressView.topAnchor.constraint(equalTo: transactionDetailsLabel.bottomAnchor, constant: 8),
            circularProgressView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circularProgressView.widthAnchor.constraint(equalToConstant: 40),
            circularProgressView.heightAnchor.constraint(equalToConstant: 40),
            
            // Gas countdown label
            gasCountdownLabel.topAnchor.constraint(equalTo: circularProgressView.bottomAnchor, constant: 8),
            gasCountdownLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gasCountdownLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Gas price label
            gasPriceLabel.topAnchor.constraint(equalTo: gasCountdownLabel.bottomAnchor, constant: 8),
            gasPriceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gasPriceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Gas limit label
            gasLimitLabel.topAnchor.constraint(equalTo: gasPriceLabel.bottomAnchor, constant: 4),
            gasLimitLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gasLimitLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Fee label
            feeLabel.topAnchor.constraint(equalTo: gasLimitLabel.bottomAnchor, constant: 4),
            feeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            feeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Total cost label
            totalCostLabel.topAnchor.constraint(equalTo: feeLabel.bottomAnchor, constant: 8),
            totalCostLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            totalCostLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Insufficient balance label
            insufficientBalanceLabel.topAnchor.constraint(equalTo: totalCostLabel.bottomAnchor, constant: 8),
            insufficientBalanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            insufficientBalanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Send button
            sendButton.topAnchor.constraint(equalTo: insufficientBalanceLabel.bottomAnchor, constant: 20),
            sendButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sendButton.heightAnchor.constraint(equalToConstant: 56),
            sendButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        // Set currency label text
        currencyLabel.text = "Sending: \(viewModel.selectedCurrency.symbol)"
        
        // Bind inputs
        toAddressTextField.rx.text
            .map { $0 ?? "" }
            .bind(to: viewModel.input.toAddress)
            .disposed(by: disposeBag)
        
        amountTextField.rx.text
            .map { $0 ?? "" }
            .bind(to: viewModel.input.amount)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleSendTransaction()
            })
            .disposed(by: disposeBag)
        
        // Bind outputs
        viewModel.output.isSendEnabled
            .drive(sendButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // ✅ Add color state binding for send button
        viewModel.output.isSendEnabled
            .drive(onNext: { [weak self] isEnabled in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.2) {
                    if isEnabled {
                        // Blue color when enabled and ready to send
                        self.sendButton.backgroundColor = UIColor.systemBlue
                        self.sendButton.setTitleColor(.white, for: .normal)
                    } else {
                        // Gray color when disabled
                        self.sendButton.backgroundColor = UIColor.systemGray4
                        self.sendButton.setTitleColor(.white, for: .disabled)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.gasPrice
            .drive(gasPriceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.gasLimit
            .drive(gasLimitLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.fee
            .drive(feeLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.totalCost
            .drive(totalCostLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.balance
            .drive(balanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.addressValidation
            .drive(addressValidationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.insufficientBalanceMessage
            .drive(insufficientBalanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.error
            .drive(onNext: { [weak self] error in
                self?.showErrorToast(error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        // Listen to gas countdown trigger
        viewModel.gasCountdownTriggerSubject
            .subscribe(onNext: { [weak self] in
                self?.startGasCountdown()
            })
            .disposed(by: disposeBag)
        
        // Set network label text
        networkLabel.text = viewModel.wallet.network.name // Default to test network
    }
    
    private func setupKeyboardHandling() {
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Add keyboard observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        // Adjust scroll view content inset
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
        
        // Scroll to active text field if needed
        DispatchQueue.main.async {
            self.scrollToActiveTextField()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset scroll view content inset
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    private func scrollToActiveTextField() {
        // Find the active text field
        let activeTextField = [toAddressTextField, amountTextField].first { $0.isFirstResponder }
        
        guard let textField = activeTextField else { return }
        
        // Calculate the frame of the text field in the scroll view
        let textFieldFrame = textField.convert(textField.bounds, to: scrollView)
        
        // Add some padding
        let padding: CGFloat = 20
        let targetRect = CGRect(
            x: textFieldFrame.origin.x,
            y: textFieldFrame.origin.y - padding,
            width: textFieldFrame.width,
            height: textFieldFrame.height + padding * 2
        )
        
        // Scroll to the text field
        scrollView.scrollRectToVisible(targetRect, animated: true)
    }
    
    // MARK: - Gas Countdown Methods
    
    private func startGasCountdown() {
        // Stop previous countdown
        stopGasCountdown()
        
        // Reset countdown
        gasCountdownSeconds = 5
        updateCountdownUI()
        
        // Start new countdown
        gasCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.gasCountdownSeconds -= 1
            self.updateCountdownUI()
            
            if self.gasCountdownSeconds <= 0 {
                self.stopGasCountdown()
                // Automatically refresh gas estimation
                self.refreshGasEstimate()
            }
        }
    }
    
    private func stopGasCountdown() {
        gasCountdownTimer?.invalidate()
        gasCountdownTimer = nil
    }
    
    private func updateCountdownUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update circular progress bar
            let progress = Float(5 - self.gasCountdownSeconds) / 5.0
            self.circularProgressView.progress = progress
            
            // Update countdown text
            if self.gasCountdownSeconds > 0 {
                self.gasCountdownLabel.text = "Gas will refresh in \(self.gasCountdownSeconds)s"
                self.circularProgressView.countdownText = "\(self.gasCountdownSeconds)"
                self.gasCountdownLabel.textColor = UIColor.secondaryLabel
            } else {
                self.gasCountdownLabel.text = "Refreshing gas..."
                self.circularProgressView.countdownText = "🔄"
                self.gasCountdownLabel.textColor = UIColor.systemBlue
            }
        }
    }
    
    private func refreshGasEstimate() {
        let toAddress = viewModel.input.toAddress.value
        let amountString = viewModel.input.amount.value
        
        guard !toAddress.isEmpty, !amountString.isEmpty,
              let amount = Decimal(string: amountString),
              amount > 0 else {
            return
        }
        
        // Re-trigger gas estimation
        Observable.zip(
            viewModel.estimateGasUseCase.estimateGas(
                from: viewModel.wallet.address,
                to: toAddress,
                amount: amount,
                currency: viewModel.selectedCurrency,
                network: viewModel.wallet.network
            ),
            viewModel.ethereumService.getGasPrice(network: viewModel.wallet.network)
                .delay(.milliseconds(300), scheduler: MainScheduler.instance)
        )
        .subscribe(onNext: { [weak self] pair in
            let (gasLimit, gasPrice) = pair
            guard let self = self else { return }
            
            // Create GasEstimate object
            let feeInETH = NSDecimalNumber(decimal: gasLimit).multiplying(by: NSDecimalNumber(decimal: gasPrice)).dividing(by: NSDecimalNumber(value: 1_000_000_000)).decimalValue
            let gasEstimate = GasEstimate(
                gasLimit: gasLimit,
                gasPrice: gasPrice,
                feeInETH: feeInETH
            )
            
            // Update gas estimation
            self.viewModel.currentGasEstimateSubject.accept(gasEstimate)
            self.viewModel.gasPriceSubject.accept("Gas Price: \(gasEstimate.formattedGasPrice)")
            self.viewModel.gasLimitSubject.accept("Gas Limit: \(gasEstimate.gasLimit)")
            self.viewModel.feeSubject.accept("Network Fee: \(gasEstimate.formattedFee)")
            
            // Restart countdown
            self.startGasCountdown()
        }, onError: { [weak self] error in
            self?.viewModel.errorSubject.accept(error)
            // Restart countdown even if error occurs
            self?.startGasCountdown()
        })
        .disposed(by: viewModel.disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopGasCountdown()
    }
    
    private func showErrorToast(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Send Progress Methods
    private func handleSendTransaction() {
        let toAddress = viewModel.input.toAddress.value
        let amountString = viewModel.input.amount.value
        
        guard !toAddress.isEmpty, !amountString.isEmpty,
              let amount = Decimal(string: amountString),
              amount > 0 else {
            return
        }
        
        // ✅ Check network connection status first
        checkNetworkStatus { [weak self] isConnected, isAirplaneMode in
            guard let self = self else { return }
            
            if isAirplaneMode {
                DispatchQueue.main.async {
                    self.showAirplaneModeAlert()
                }
                return
            }
            
            if !isConnected {
                DispatchQueue.main.async {
                    self.showNetworkDisconnectedAlert()
                }
                return
            }
            
            // ✅ Network is normal, check if ETH balance is sufficient to pay gas fees
            self.checkETHBalanceForGasFee { [weak self] hasEnoughETH, ethBalance in
                guard let self = self else { return }
                
                if !hasEnoughETH {
                    // ✅ Show insufficient ETH balance alert
                    let errorMessage = (ethBalance ?? 0) == 0 ?
                        "No ETH balance. Please deposit some ETH to pay for gas fees." :
                        "Insufficient ETH balance to pay gas fees. Please deposit more ETH."
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "Insufficient ETH Balance",
                            message: errorMessage,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                    return
                }
                
                // ✅ ETH balance is sufficient, show confirmation alert
                DispatchQueue.main.async {
                    self.showConfirmationAlert(toAddress: toAddress, amount: amount, amountString: amountString)
                }
            }
        }
    }
    
    private func showConfirmationAlert(toAddress: String, amount: Decimal, amountString: String) {
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Confirm Transaction",
            message: "Send \(amountString) \(viewModel.selectedCurrency.symbol) to \(toAddress)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            self?.executeSendTransaction(to: toAddress, amount: amount)
        })
        
        present(alert, animated: true)
    }
    
    private func executeSendTransaction(to address: String, amount: Decimal) {
        // Show progress page
        showSendProgressPage()
        
        // Simulate transaction sending process
        simulateTransactionSending(to: address, amount: amount)
    }
    
    private func showSendProgressPage() {
        let progressVC = SendProgressViewController(
            onClose: { [weak self] in
                self?.dismissProgressPage()
            },
            onViewTransaction: { [weak self] txHash in
                self?.viewTransaction(txHash)
            }
        )
        
        progressVC.modalPresentationStyle = .overFullScreen
        progressVC.modalTransitionStyle = .crossDissolve
        
        DispatchQueue.main.async {
            self.present(progressVC, animated: true)
        }
        
        // Store reference for updates
        self.progressViewController = progressVC
    }
    
    private func dismissProgressPage() {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                // Navigate back to wallet home
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func viewTransaction(_ txHash: String) {
        // Open transaction in browser
        let urlString = "https://sepolia.etherscan.io/tx/\(txHash)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func goToHistory() {
        // Navigate to transaction history
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                // Post notification to show transaction history
                NotificationCenter.default.post(name: .showTransactionHistory, object: nil)
            }
        }
    }
    
    // MARK: - ETH Balance Check
    
    private func checkETHBalanceForGasFee(completion: @escaping (Bool, Decimal?) -> Void) {
        // Get ETH balance
        let appContainer = AppContainer()
        let ethereumService = appContainer.ethereumService
        
        // Create ETH currency object
        let ethCurrency = Currency(
            symbol: "ETH",
            name: "Ethereum",
            decimals: 18,
            contractAddress: nil
        )
        
        ethereumService.getBalance(address: viewModel.wallet.address, currency: ethCurrency, network: viewModel.wallet.network)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] ethBalance in
                    guard let self = self,
                          let gasEstimate = self.viewModel.currentGasEstimateSubject.value else {
                        completion(false, nil)
                        return
                    }
                    
                    // Calculate required gas fee (ETH)
                    let gasFeeInETH = gasEstimate.feeInETH
                    
                    // ✅ Double check: 1) ETH balance cannot be 0 2) Balance must be sufficient to pay gas fees
                    let hasETH = ethBalance > 0
                    let hasEnoughETH = ethBalance >= gasFeeInETH
                    let canSendTransaction = hasETH && hasEnoughETH
                    
                    if !hasETH {
                        print("⚠️ No ETH balance: \(ethBalance) ETH - Account has no ETH")
                    } else if !hasEnoughETH {
                        print("⚠️ Insufficient ETH balance: \(ethBalance) ETH, needed: \(gasFeeInETH) ETH")
                    } else {
                        print("✅ ETH balance sufficient: \(ethBalance) ETH, needed: \(gasFeeInETH) ETH")
                    }
                    
                    completion(canSendTransaction, ethBalance)
                },
                onError: { error in
                    print("❌ Failed to check ETH balance: \(error)")
                    completion(false, nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func simulateTransactionSending(to address: String, amount: Decimal) {
        // ✅ Check if ETH balance is sufficient to pay gas fees
        checkETHBalanceForGasFee { [weak self] hasEnoughETH, ethBalance in
            guard let self = self else { return }
            
            if !hasEnoughETH {
                // ✅ More specific error message
                let errorMessage = (ethBalance ?? 0) == 0 ? 
                    "No ETH balance. Please deposit some ETH to pay for gas fees." :
                    "Insufficient ETH balance to pay gas fees. Please deposit more ETH."
                self.progressViewController?.updateStatus(.failed(error: WalletError.networkError(errorMessage)))
                return
            }
            
            // ✅ Use real transaction sending instead of simulation
            guard let gasEstimate = self.viewModel.currentGasEstimateSubject.value else {
                self.progressViewController?.updateStatus(.failed(error: WalletError.networkError("Gas estimate not available")))
                return
            }
            
            // Get mnemonic
            let keychainStorage = KeychainStorageService()
            guard let mnemonic = keychainStorage.retrieve(key: "mnemonic_\(self.viewModel.wallet.address)") else {
                self.progressViewController?.updateStatus(.failed(error: WalletError.networkError("Mnemonic not found")))
                return
            }
            
            // Send real transaction
            self.viewModel.sendTransactionUseCase.sendTransaction(
                from: self.viewModel.wallet,
                to: address,
                amount: amount,
                currency: self.viewModel.selectedCurrency,
                gasEstimate: gasEstimate,
                mnemonic: mnemonic
            )
            .subscribe(
                onNext: { [weak self] txHash in
                    // ✅ Update status to success
                    self?.progressViewController?.updateStatus(.success(txHash: txHash))
                    
                    // ✅ Show success action options
                    self?.showSuccessOptions(txHash: txHash)
                },
                onError: { [weak self] error in
                    // ✅ Update status to failed
                    self?.progressViewController?.updateStatus(.failed(error: error))
                }
            )
            .disposed(by: self.viewModel.disposeBag)
        }
    }
    
    // MARK: - Success Options
    
    private func showSuccessOptions(txHash: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(
                title: "Transaction Sent Successfully!",
                message: "Transaction Hash: \(txHash)",
                preferredStyle: .alert
            )
            
            // Copy transaction ID
            alert.addAction(UIAlertAction(title: "Copy Transaction ID", style: .default) { _ in
                UIPasteboard.general.string = txHash
                self.showToast("Transaction ID copied to clipboard")
            })
            
            // View on Etherscan
            alert.addAction(UIAlertAction(title: "View on Etherscan", style: .default) { _ in
                let etherscanURL = "https://sepolia.etherscan.io/tx/\(txHash)"
                if let url = URL(string: etherscanURL) {
                    UIApplication.shared.open(url)
                }
            })
            
            // Navigate to transaction history
            alert.addAction(UIAlertAction(title: "View Transaction History", style: .default) { _ in
                self.goToHistory()
            })
            
            // Close progress page
            alert.addAction(UIAlertAction(title: "Close", style: .cancel) { _ in
                self.dismissProgressPage()
            })
            
            self.present(alert, animated: true)
        }
    }
    
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    // MARK: - Wallet Switching Listener
    
    private func setupWalletSwitchingListener() {
        NotificationCenter.default.rx
            .notification(.walletSwitched)
            .compactMap { $0.object as? Wallet }
            .subscribe(onNext: { [weak self] newWallet in
                guard let self = self else { return }
                
                // ✅ Update ViewModel's wallet
                self.viewModel.updateWallet(newWallet)
                
                // ✅ Update network label
                self.networkLabel.text = newWallet.network.name
                
                print("🔄 Send page updated for wallet: \(newWallet.address)")
        })
        .disposed(by: disposeBag)
    }
    
    // MARK: - Network Status Check
    
    private func checkNetworkStatus(completion: @escaping (Bool, Bool) -> Void) {
        let appContainer = AppContainer()
        let networkStatusService = appContainer.networkStatusService
        
        // Get current network status
        let isConnected = networkStatusService.isConnectedSubject.value
        let isAirplaneMode = networkStatusService.isAirplaneModeSubject.value
        
        completion(isConnected, isAirplaneMode)
    }
    
    private func showAirplaneModeAlert() {
        let alert = UIAlertController(
            title: "Airplane Mode Detected",
            message: "Please turn off airplane mode to send transactions. Transaction sending requires internet connection.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Add settings action if available
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                UIApplication.shared.open(settingsUrl)
            })
        }
        
        present(alert, animated: true)
    }
    
    private func showNetworkDisconnectedAlert() {
        let alert = UIAlertController(
            title: "No Internet Connection",
            message: "Please check your internet connection. Transaction sending requires internet connection.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}


// MARK: - Circular Progress View
class CircularProgressView: UIView {
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    private let countdownLabel = UILabel()
    
    var progress: Float = 0.0 {
        didSet {
            updateProgress()
        }
    }
    
    var countdownText: String = "" {
        didSet {
            countdownLabel.text = countdownText
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Setup background circle
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.systemGray5.cgColor
        backgroundLayer.lineWidth = 3
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)
        
        // Setup progress circle
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.lineWidth = 3
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        // Setup countdown label
        countdownLabel.textAlignment = .center
        countdownLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        countdownLabel.textColor = UIColor.systemBlue
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countdownLabel)
        
        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        backgroundLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }
    
    private func updateProgress() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = progress
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        progressLayer.strokeEnd = CGFloat(progress)
        progressLayer.add(animation, forKey: "progressAnimation")
    }
}
