//
//  GasEstimate.swift
//  Web3Wallet
//

import Foundation

struct GasEstimate {
    let gasLimit: Decimal
    let gasPrice: Decimal
    let feeInETH: Decimal
    
    var formattedGasPrice: String {
        return String(format: "%.2f Gwei", gasPrice.doubleValue)
    }
    
    var formattedFee: String {
        return String(format: "%.6f ETH", feeInETH.doubleValue)
    }
}
