//
//  Logger.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import os.log

/// Log level
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        }
    }
}

/// Logger utility class
class Logger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Web3Wallet"
    private static let category = "General"
    
    private static let osLog = OSLog(subsystem: subsystem, category: category)
    
    /// List of sensitive fields (values of these fields will be masked)
    private static let sensitiveFields = [
        "mnemonic", "seed", "privateKey", "password", "pin",
        "token", "key", "secret", "auth", "credential"
    ]
    
    /// Log debug message
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    /// Log info message
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    /// Log warning message
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    /// Log error message
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    /// Log error message (with error object)
    static func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: error.localizedDescription, file: file, function: function, line: line)
    }
    
    /// Log network request
    static func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let networkLog = OSLog(subsystem: subsystem, category: "Network")
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: networkLog, type: .debug, logMessage)
        #endif
    }
    
    /// Log wallet-related messages (sensitive information will be masked)
    static func wallet(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let walletLog = OSLog(subsystem: subsystem, category: "Wallet")
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: walletLog, type: .info, logMessage)
    }
    
    /// Mask sensitive information
    static func redact(_ value: String) -> String {
        return "***"
    }
    
    /// Mask sensitive fields
    static func redactSensitiveFields(_ dictionary: [String: Any]) -> [String: Any] {
        var redactedDict = dictionary
        
        for (key, value) in dictionary {
            let lowercasedKey = key.lowercased()
            if sensitiveFields.contains(where: { lowercasedKey.contains($0) }) {
                redactedDict[key] = "***"
            } else if let dict = value as? [String: Any] {
                redactedDict[key] = redactSensitiveFields(dict)
            }
        }
        
        return redactedDict
    }
    
    /// Internal logging method
    private static func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        #if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        #endif
    }
}

/// Log tags
struct LogTag {
    static let network = "NETWORK"
    static let wallet = "WALLET"
    static let ui = "UI"
    static let storage = "STORAGE"
    static let cache = "CACHE"
    static let validation = "VALIDATION"
    static let error = "ERROR"
}
