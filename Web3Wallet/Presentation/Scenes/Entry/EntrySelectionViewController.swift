//
//  EntrySelectionViewController.swift
//  trust_wallet2
//
//  Created by Codex on 2025/10/30.
//

import UIKit

/// Landing screen that lets users choose between the native UIKit wallet
/// and the React Native implementation.
final class EntrySelectionViewController: UIViewController {
    
    // MARK: - Callbacks
    var onSelectNative: (() -> Void)?
    var onSelectReactNative: (() -> Void)?
    
    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Wallet Experience"
        label.font = .boldSystemFont(ofSize: 26)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "You can use the production-ready native UIKit wallet or try the upcoming React Native version."
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let nativeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open Native Wallet", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let reactButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open React Native Wallet", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupActions()
    }
    
    private func setupLayout() {
        view.backgroundColor = .systemBackground
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        nativeButton.translatesAutoresizingMaskIntoConstraints = false
        reactButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stackView)
        
        stackView.addArrangedSubview(nativeButton)
        stackView.addArrangedSubview(reactButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
        
        nativeButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        reactButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
    
    private func setupActions() {
        nativeButton.addTarget(self, action: #selector(handleNativeTapped), for: .touchUpInside)
        reactButton.addTarget(self, action: #selector(handleReactTapped), for: .touchUpInside)
    }
    
    @objc private func handleNativeTapped() {
        onSelectNative?()
    }
    
    @objc private func handleReactTapped() {
        onSelectReactNative?()
    }
}
