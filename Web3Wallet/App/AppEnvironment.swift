//
//  AppEnvironment.swift
//  trust_wallet2
//
//  Created by Codex on 2025/01/17.
//

import Foundation

enum AppEnvironment {
    
    /// 检测当前是否运行在单元测试环境中
    static var isRunningUnitTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
