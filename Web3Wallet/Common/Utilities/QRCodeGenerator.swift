//
//  QRCodeGenerator.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

/// QR code generator
class QRCodeGenerator {
    
    /// Generate QR code image
    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        let context = CIContext()
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        
        guard let filter = filter, let outputImage = filter.outputImage else { return nil }
        
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generate QR code image with color
    static func generateQRCode(from string: String, 
                             size: CGSize = CGSize(width: 200, height: 200),
                             foregroundColor: UIColor = .black,
                             backgroundColor: UIColor = .white) -> UIImage? {
        guard let qrImage = generateQRCode(from: string, size: size) else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            qrImage.draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: 1.0)
        }
    }
    
    /// Generate QR code image with logo
    static func generateQRCodeWithLogo(from string: String,
                                     size: CGSize = CGSize(width: 200, height: 200),
                                     logo: UIImage?,
                                     logoSize: CGSize = CGSize(width: 40, height: 40)) -> UIImage? {
        guard let qrImage = generateQRCode(from: string, size: size) else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Draw QR code
            qrImage.draw(in: CGRect(origin: .zero, size: size))
            
            // Draw logo
            if let logo = logo {
                let logoRect = CGRect(
                    x: (size.width - logoSize.width) / 2,
                    y: (size.height - logoSize.height) / 2,
                    width: logoSize.width,
                    height: logoSize.height
                )
                
                // Draw white background
                UIColor.white.setFill()
                context.fill(logoRect.insetBy(dx: -2, dy: -2))
                
                // Draw logo
                logo.draw(in: logoRect)
            }
        }
    }
    
    /// Generate wallet address QR code
    static func generateWalletQRCode(address: String, 
                                   size: CGSize = CGSize(width: 200, height: 200),
                                   includeLogo: Bool = true) -> UIImage? {
        let qrString = "ethereum:\(address)"
        
        if includeLogo {
            // Wallet logo can be added here
            return generateQRCodeWithLogo(from: qrString, size: size, logo: nil)
        } else {
            return generateQRCode(from: qrString, size: size)
        }
    }
    
    /// Generate payment QR code
    static func generatePaymentQRCode(address: String,
                                    amount: Decimal?,
                                    token: String = "ETH",
                                    size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        var qrString = "ethereum:\(address)"
        
        if let amount = amount {
            qrString += "?value=\(amount.stringValue)"
        }
        
        if token != "ETH" {
            qrString += "&token=\(token)"
        }
        
        return generateQRCode(from: qrString, size: size)
    }
}

/// QR code scan result
struct QRCodeScanResult {
    let string: String
    let type: QRCodeType
    
    enum QRCodeType {
        case ethereumAddress
        case ethereumPayment
        case plainText
        case unknown
    }
    
    init(string: String) {
        self.string = string
        
        if string.hasPrefix("ethereum:") {
            let address = String(string.dropFirst(9))
            if address.isValidEthereumAddressFormat {
                self.type = .ethereumAddress
            } else {
                self.type = .ethereumPayment
            }
        } else if string.isValidEthereumAddressFormat {
            self.type = .ethereumAddress
        } else {
            self.type = .plainText
        }
    }
}

/// QR code utility extension
extension UIImage {
    
    /// Generate QR code
    static func qrCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        return QRCodeGenerator.generateQRCode(from: string, size: size)
    }
    
    /// Generate QR code with color
    static func qrCode(from string: String, 
                      size: CGSize = CGSize(width: 200, height: 200),
                      foregroundColor: UIColor = .black,
                      backgroundColor: UIColor = .white) -> UIImage? {
        return QRCodeGenerator.generateQRCode(from: string, 
                                            size: size, 
                                            foregroundColor: foregroundColor, 
                                            backgroundColor: backgroundColor)
    }
}
