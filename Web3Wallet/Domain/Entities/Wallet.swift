//
//  Wallet.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Wallet entity
/// Contains basic wallet information and status
struct Wallet: Equatable, Codable {
    let id: String
    let name: String
    let address: String
    let network: Network
    let createdAt: Date
    let isImported: Bool
    let fingerprint: String
    
    /// Wallet display name
    var displayName: String {
        return name.isEmpty ? "Wallet \(id.prefix(8))" : name
    }
    
    /// Formatted address display
    var formattedAddress: String {
        return formatAddress(address)
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let prefix = String(address.prefix(6))
        let suffix = String(address.suffix(4))
        return "\(prefix)…\(suffix)"
    }
    
    init(id: String = UUID().uuidString,
         name: String = "",
         address: String,
         network: Network,
         createdAt: Date = Date(),
         isImported: Bool = false,
         fingerprint: String = "") {
        self.id = id
        self.name = name
        self.address = address
        self.network = network
        self.createdAt = createdAt
        self.isImported = isImported
        self.fingerprint = fingerprint.isEmpty ? address : fingerprint
    }
}
