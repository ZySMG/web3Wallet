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

/// 二维码生成器
class QRCodeGenerator {
    
    /// 生成二维码图片
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
    
    /// 生成带颜色的二维码图片
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
    
    /// 生成带 Logo 的二维码图片
    static func generateQRCodeWithLogo(from string: String,
                                     size: CGSize = CGSize(width: 200, height: 200),
                                     logo: UIImage?,
                                     logoSize: CGSize = CGSize(width: 40, height: 40)) -> UIImage? {
        guard let qrImage = generateQRCode(from: string, size: size) else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 绘制二维码
            qrImage.draw(in: CGRect(origin: .zero, size: size))
            
            // 绘制 Logo
            if let logo = logo {
                let logoRect = CGRect(
                    x: (size.width - logoSize.width) / 2,
                    y: (size.height - logoSize.height) / 2,
                    width: logoSize.width,
                    height: logoSize.height
                )
                
                // 绘制白色背景
                UIColor.white.setFill()
                context.fill(logoRect.insetBy(dx: -2, dy: -2))
                
                // 绘制 Logo
                logo.draw(in: logoRect)
            }
        }
    }
    
    /// 生成钱包地址二维码
    static func generateWalletQRCode(address: String, 
                                   size: CGSize = CGSize(width: 200, height: 200),
                                   includeLogo: Bool = true) -> UIImage? {
        let qrString = "ethereum:\(address)"
        
        if includeLogo {
            // 这里可以添加钱包 Logo
            return generateQRCodeWithLogo(from: qrString, size: size, logo: nil)
        } else {
            return generateQRCode(from: qrString, size: size)
        }
    }
    
    /// 生成支付二维码
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

/// 二维码扫描结果
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

/// 二维码工具扩展
extension UIImage {
    
    /// 生成二维码
    static func qrCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        return QRCodeGenerator.generateQRCode(from: string, size: size)
    }
    
    /// 生成带颜色的二维码
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
