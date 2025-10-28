//
//  ValidationTests.swift
//  Web3WalletTests
//
//  Created by Web3Wallet on 2025/01/01.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import XCTest
@testable import Web3Wallet

class ValidationTests: XCTestCase {
    
    var mnemonicValidator: MnemonicValidatorProtocol!
    var addressValidator: AddressValidatorProtocol!
    
    override func setUp() {
        super.setUp()
        mnemonicValidator = MnemonicValidator()
        addressValidator = AddressValidator()
    }
    
    override func tearDown() {
        mnemonicValidator = nil
        addressValidator = nil
        super.tearDown()
    }
    
    // MARK: - Mnemonic Validation Tests
    
    func testValidMnemonic() {
        let validMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        XCTAssertTrue(mnemonicValidator.isValid(validMnemonic))
    }
    
    func testInvalidMnemonicWordCount() {
        let invalidMnemonic = "abandon abandon abandon"
        XCTAssertFalse(mnemonicValidator.validateWordCount(invalidMnemonic))
    }
    
    func testInvalidMnemonicWords() {
        let invalidMnemonic = "invalid invalid invalid invalid invalid invalid invalid invalid invalid invalid invalid invalid"
        XCTAssertFalse(mnemonicValidator.validateWords(invalidMnemonic))
    }
    
    func testMnemonicValidationError() {
        let invalidMnemonic = "abandon abandon"
        let error = mnemonicValidator.getValidationError(invalidMnemonic)
        XCTAssertNotNil(error)
        XCTAssertTrue(error!.contains("12"))
    }
    
    // MARK: - Address Validation Tests
    
    func testValidEthereumAddress() {
        let validAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
        XCTAssertTrue(addressValidator.isValid(validAddress))
    }
    
    func testInvalidAddressFormat() {
        let invalidAddress = "742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
        XCTAssertFalse(addressValidator.isValid(invalidAddress))
    }
    
    func testInvalidAddressLength() {
        let invalidAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bE"
        XCTAssertFalse(addressValidator.isValid(invalidAddress))
    }
    
    func testAddressValidationError() {
        let invalidAddress = "invalid"
        let error = addressValidator.getValidationError(invalidAddress)
        XCTAssertNotNil(error)
        XCTAssertTrue(error!.contains("0x"))
    }
    
    func testAddressNormalization() {
        let address = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
        let normalized = addressValidator.normalizeAddress(address)
        XCTAssertEqual(normalized, address.lowercased())
    }
    
    // MARK: - EIP-55 Tests
    
    func testEIP55Validation() {
        let checksumAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
        XCTAssertTrue(EIP55.isValid(checksumAddress))
    }
    
    func testEIP55ToChecksum() {
        let lowercaseAddress = "0x742d35cc6634c0532925a3b844bc9e7595f0beb"
        let checksumAddress = EIP55.toChecksumAddress(lowercaseAddress)
        XCTAssertNotEqual(checksumAddress, lowercaseAddress)
        XCTAssertTrue(EIP55.isValid(checksumAddress))
    }
}
