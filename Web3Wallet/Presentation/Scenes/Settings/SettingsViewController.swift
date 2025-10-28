//
//  SettingsViewController.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Settings view controller for API configuration
class SettingsViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    // API Key input fields
    private let etherscanMainnetField = UITextField()
    private let etherscanSepoliaField = UITextField()
    private let coinGeckoField = UITextField()
    private let coinMarketCapField = UITextField()
    private let moralisField = UITextField()
    private let alchemyMainnetField = UITextField()
    private let alchemySepoliaField = UITextField()
    private let infuraMainnetField = UITextField()
    private let infuraSepoliaField = UITextField()
    
    // Buttons
    private let saveButton = UIButton(type: .system)
    private let testConnectionButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    
    // Status labels
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSettings()
        bindActions()
    }
    
    private func setupUI() {
        title = "API Settings"
        view.backgroundColor = UIColor.systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Add sections
        addEtherscanSection()
        addCoinGeckoSection()
        addCoinMarketCapSection()
        addMoralisSection()
        addAlchemySection()
        addInfuraSection()
        addActionButtons()
        addStatusSection()
        
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
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func addEtherscanSection() {
        let section = createSection(title: "Etherscan API Keys", description: "Required for transaction history and balance queries")
        
        etherscanMainnetField.placeholder = "Mainnet API Key"
        etherscanSepoliaField.placeholder = "Sepolia Testnet API Key"
        
        section.addArrangedSubview(createTextFieldStack(labelText: "Mainnet:", field: etherscanMainnetField))
        section.addArrangedSubview(createTextFieldStack(labelText: "Sepolia:", field: etherscanSepoliaField))
        
        stackView.addArrangedSubview(section)
    }
    
    private func addCoinGeckoSection() {
        let section = createSection(title: "CoinGecko API Key", description: "Premium price data service")
        
        coinGeckoField.placeholder = "CoinGecko API Key"
        section.addArrangedSubview(createTextFieldStack(labelText: "API Key:", field: coinGeckoField))
        
        stackView.addArrangedSubview(section)
    }
    
    private func addCoinMarketCapSection() {
        let section = createSection(title: "CoinMarketCap API Key", description: "Free alternative to CoinGecko for price data")
        
        coinMarketCapField.placeholder = "CoinMarketCap API Key"
        section.addArrangedSubview(createTextFieldStack(labelText: "API Key:", field: coinMarketCapField))
        
        stackView.addArrangedSubview(section)
    }
    
    private func addMoralisSection() {
        let section = createSection(title: "Moralis API Key", description: "Free alternative for blockchain data and price information")
        
        moralisField.placeholder = "Moralis API Key"
        section.addArrangedSubview(createTextFieldStack(labelText: "API Key:", field: moralisField))
        
        stackView.addArrangedSubview(section)
    }
    
    private func addAlchemySection() {
        let section = createSection(title: "Alchemy API Keys", description: "Optional, for enhanced Ethereum data")
        
        alchemyMainnetField.placeholder = "Mainnet API Key"
        alchemySepoliaField.placeholder = "Sepolia Testnet API Key"
        
        section.addArrangedSubview(createTextFieldStack(labelText: "Mainnet:", field: alchemyMainnetField))
        section.addArrangedSubview(createTextFieldStack(labelText: "Sepolia:", field: alchemySepoliaField))
        
        stackView.addArrangedSubview(section)
    }
    
    private func addInfuraSection() {
        let section = createSection(title: "Infura API Keys", description: "Optional, alternative to Alchemy")
        
        infuraMainnetField.placeholder = "Mainnet API Key"
        infuraSepoliaField.placeholder = "Sepolia Testnet API Key"
        
        section.addArrangedSubview(createTextFieldStack(labelText: "Mainnet:", field: infuraMainnetField))
        section.addArrangedSubview(createTextFieldStack(labelText: "Sepolia:", field: infuraSepoliaField))
        
        stackView.addArrangedSubview(section)
    }
    
    private func addActionButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        
        // Save button
        saveButton.setTitle("Save Settings", for: .normal)
        saveButton.backgroundColor = UIColor.systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Test connection button
        testConnectionButton.setTitle("Test Connection", for: .normal)
        testConnectionButton.backgroundColor = UIColor.systemGreen
        testConnectionButton.setTitleColor(.white, for: .normal)
        testConnectionButton.layer.cornerRadius = 8
        testConnectionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Reset button
        resetButton.setTitle("Reset to Defaults", for: .normal)
        resetButton.backgroundColor = UIColor.systemRed
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 8
        resetButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        buttonStack.addArrangedSubview(saveButton)
        buttonStack.addArrangedSubview(testConnectionButton)
        buttonStack.addArrangedSubview(resetButton)
        
        stackView.addArrangedSubview(buttonStack)
    }
    
    private func addStatusSection() {
        let section = createSection(title: "Status", description: "Current API configuration status")
        
        statusLabel.text = "No API keys configured"
        statusLabel.textColor = UIColor.systemOrange
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        
        section.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(section)
    }
    
    private func createSection(title: String, description: String) -> UIStackView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 12
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor.label
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.textColor = UIColor.secondaryLabel
        descLabel.numberOfLines = 0
        
        section.addArrangedSubview(titleLabel)
        section.addArrangedSubview(descLabel)
        
        return section
    }
    
    private func createTextFieldStack(labelText: String, field: UITextField) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        
        let label = UILabel()
        label.text = labelText
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.label
        
        field.borderStyle = .roundedRect
        field.font = UIFont.systemFont(ofSize: 16)
        field.isSecureTextEntry = true
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(field)
        
        return stack
    }
    
    private func loadCurrentSettings() {
        // Load current API keys from UserDefaults or secure storage
        etherscanMainnetField.text = UserDefaults.standard.string(forKey: "etherscan_mainnet_key") ?? ""
        etherscanSepoliaField.text = UserDefaults.standard.string(forKey: "etherscan_sepolia_key") ?? ""
        coinGeckoField.text = UserDefaults.standard.string(forKey: "coingecko_key") ?? ""
        coinMarketCapField.text = UserDefaults.standard.string(forKey: "coinmarketcap_key") ?? ""
        moralisField.text = UserDefaults.standard.string(forKey: "moralis_key") ?? ""
        alchemyMainnetField.text = UserDefaults.standard.string(forKey: "alchemy_mainnet_key") ?? ""
        alchemySepoliaField.text = UserDefaults.standard.string(forKey: "alchemy_sepolia_key") ?? ""
        infuraMainnetField.text = UserDefaults.standard.string(forKey: "infura_mainnet_key") ?? ""
        infuraSepoliaField.text = UserDefaults.standard.string(forKey: "infura_sepolia_key") ?? ""
        
        updateStatus()
    }
    
    private func bindActions() {
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveSettings()
            })
            .disposed(by: disposeBag)
        
        testConnectionButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.testConnection()
            })
            .disposed(by: disposeBag)
        
        resetButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.resetSettings()
            })
            .disposed(by: disposeBag)
    }
    
    private func saveSettings() {
        // Save API keys to UserDefaults (in production, use Keychain)
        UserDefaults.standard.set(etherscanMainnetField.text, forKey: "etherscan_mainnet_key")
        UserDefaults.standard.set(etherscanSepoliaField.text, forKey: "etherscan_sepolia_key")
        UserDefaults.standard.set(coinGeckoField.text, forKey: "coingecko_key")
        UserDefaults.standard.set(coinMarketCapField.text, forKey: "coinmarketcap_key")
        UserDefaults.standard.set(moralisField.text, forKey: "moralis_key")
        UserDefaults.standard.set(alchemyMainnetField.text, forKey: "alchemy_mainnet_key")
        UserDefaults.standard.set(alchemySepoliaField.text, forKey: "alchemy_sepolia_key")
        UserDefaults.standard.set(infuraMainnetField.text, forKey: "infura_mainnet_key")
        UserDefaults.standard.set(infuraSepoliaField.text, forKey: "infura_sepolia_key")
        
        updateStatus()
        showSuccessToast("Settings saved successfully!")
    }
    
    private func testConnection() {
        showInfoToast("API test functionality has been removed")
    }
    
    private func handleAPITestResults(_ results: [String: Bool]) {
        var successCount = 0
        var totalCount = results.count
        var statusMessage = "API Test Results:\n"
        
        for (service, isWorking) in results {
            let status = isWorking ? "✅" : "❌"
            statusMessage += "\(status) \(service)\n"
            if isWorking { successCount += 1 }
        }
        
        statusMessage += "\n\(successCount)/\(totalCount) services working"
        
        if successCount == totalCount {
            showSuccessToast("All API keys are working!")
        } else if successCount > 0 {
            showWarningToast("Some API keys are working")
        } else {
            showErrorToast("No API keys are working")
        }
        
        // Update status display
        updateStatus()
    }
    
    private func resetSettings() {
        let alert = UIAlertController(
            title: "Reset Settings",
            message: "Are you sure you want to reset all API keys?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.performReset()
        })
        
        present(alert, animated: true)
    }
    
    private func performReset() {
        etherscanMainnetField.text = ""
        etherscanSepoliaField.text = ""
        coinGeckoField.text = ""
        alchemyMainnetField.text = ""
        alchemySepoliaField.text = ""
        infuraMainnetField.text = ""
        infuraSepoliaField.text = ""
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "etherscan_mainnet_key")
        UserDefaults.standard.removeObject(forKey: "etherscan_sepolia_key")
        UserDefaults.standard.removeObject(forKey: "coingecko_key")
        UserDefaults.standard.removeObject(forKey: "alchemy_mainnet_key")
        UserDefaults.standard.removeObject(forKey: "alchemy_sepolia_key")
        UserDefaults.standard.removeObject(forKey: "infura_mainnet_key")
        UserDefaults.standard.removeObject(forKey: "infura_sepolia_key")
        
        updateStatus()
        showSuccessToast("Settings reset successfully!")
    }
    
    private func updateStatus() {
        let hasEtherscan = !etherscanMainnetField.text!.isEmpty || !etherscanSepoliaField.text!.isEmpty
        let hasCoinGecko = !coinGeckoField.text!.isEmpty
        let hasCoinMarketCap = !coinMarketCapField.text!.isEmpty
        let hasMoralis = !moralisField.text!.isEmpty
        let hasAlchemy = !alchemyMainnetField.text!.isEmpty || !alchemySepoliaField.text!.isEmpty
        let hasInfura = !infuraMainnetField.text!.isEmpty || !infuraSepoliaField.text!.isEmpty
        
        var statusText = ""
        var statusColor = UIColor.systemOrange
        
        if hasEtherscan && (hasCoinGecko || hasCoinMarketCap || hasMoralis) {
            statusText = "✅ Full configuration\n• Real transaction data\n• Real price data\n• Enhanced features available"
            statusColor = UIColor.systemGreen
        } else if hasEtherscan || hasCoinGecko || hasCoinMarketCap || hasMoralis {
            statusText = "⚠️ Partial configuration\n• Some real data available\n• Using Alternative.me for missing data"
            statusColor = UIColor.systemYellow
        } else {
            statusText = "ℹ️ Using Alternative.me free service\n• No API keys required\n• Basic functionality available"
            statusColor = UIColor.systemBlue
        }
        
        if hasAlchemy {
            statusText += "\n• Alchemy integration available"
        }
        
        if hasInfura {
            statusText += "\n• Infura integration available"
        }
        
        statusLabel.text = statusText
        statusLabel.textColor = statusColor
    }
}
