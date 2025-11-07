//
//  ReactNativePlaceholderViewController.swift
//  trust_wallet2
//
//  Created by Codex on 2025/10/30.
//

import UIKit

/// Temporary container that outlines the React Native integration status.
/// Once the React Native bundle is available, this controller can host `RCTRootView`.
final class ReactNativePlaceholderViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "React Native Wallet (Preview)"
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = """
The React Native wallet is under active development. Clone the repo, install the JavaScript dependencies inside `ReactNativeWallet/`, and run Metro to load the RN UI.

Until the JavaScript bundle is available, this screen displays implementation notes and integration steps.
"""
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let instructionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open React Native Setup Guide", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        [titleLabel, descriptionLabel, instructionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            instructionsButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 36),
            instructionsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            instructionsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            instructionsButton.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        instructionsButton.addTarget(self, action: #selector(openGuide), for: .touchUpInside)
    }
    
    @objc private func openGuide() {
        guard let url = URL(string: "https://github.com/user/repo#react-native-wallet") else { return }
        UIApplication.shared.open(url)
    }
}
