//
//  MnemonicValidator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import WalletCore

/// Mnemonic validator protocol
protocol MnemonicValidatorProtocol {
    func isValid(_ mnemonic: String) -> Bool
    func validateWordCount(_ mnemonic: String) -> Bool
    func validateWords(_ mnemonic: String) -> Bool
}

/// Mnemonic validator
/// Responsible for validating mnemonic phrases
class MnemonicValidator: MnemonicValidatorProtocol {
    
    /// Supported mnemonic lengths
    private let supportedWordCounts = [12, 15, 18, 21, 24]
    
    func isValid(_ mnemonic: String) -> Bool {
        return validateWordCount(mnemonic) && validateWords(mnemonic)
    }
    
    func validateWordCount(_ mnemonic: String) -> Bool {
        let words = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        return supportedWordCounts.contains(words.count)
    }
    
    func validateWords(_ mnemonic: String) -> Bool {
        // Use TrustWalletCore to validate mnemonic
        return Mnemonic.isValid(mnemonic: mnemonic)
    }
    
    /// Get mnemonic validation error message
    func getValidationError(_ mnemonic: String) -> String? {
        let words = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        if words.count == 0 {
            return "Mnemonic cannot be empty"
        }
        
        if !supportedWordCounts.contains(words.count) {
            return "Mnemonic must be \(supportedWordCounts.map(String.init).joined(separator: ", ")) words"
        }
        
        if !validateWords(mnemonic) {
            return "Mnemonic contains invalid words"
        }
        
        return nil
    }
}
