//
//  MnemonicValidator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import WalletCore

/// 助记词验证器协议
protocol MnemonicValidatorProtocol {
    func isValid(_ mnemonic: String) -> Bool
    func validateWordCount(_ mnemonic: String) -> Bool
    func validateWords(_ mnemonic: String) -> Bool
}

/// 助记词验证器
/// 负责验证助记词的有效性
class MnemonicValidator: MnemonicValidatorProtocol {
    
    /// 支持的助记词长度
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
        // 使用 TrustWalletCore 验证助记词
        return Mnemonic.isValid(mnemonic: mnemonic)
    }
    
    /// 获取助记词错误信息
    func getValidationError(_ mnemonic: String) -> String? {
        let words = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        if words.count == 0 {
            return "助记词不能为空"
        }
        
        if !supportedWordCounts.contains(words.count) {
            return "助记词必须是 \(supportedWordCounts.map(String.init).joined(separator: "、")) 个单词"
        }
        
        if !validateWords(mnemonic) {
            return "助记词包含无效单词"
        }
        
        return nil
    }
}
