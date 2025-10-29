source 'https://cdn.cocoapods.org/'
platform :ios, '15.0'

target 'trust_wallet2' do
  use_frameworks!
  
  # RxSwift for reactive programming
  pod 'RxSwift', '~> 6.0'
  pod 'RxCocoa', '~> 6.0'
  
  # Trust Wallet 核心库，提供多链签名和密钥管理功能
  pod 'TrustWalletCore'
  
  # Networking
  pod 'Alamofire', '~> 5.0'
end

target 'Web3WalletTests' do
  inherit! :search_paths
  use_frameworks!
  pod 'RxSwift', '~> 6.0'
  pod 'RxCocoa', '~> 6.0'
  pod 'TrustWalletCore'
  pod 'Alamofire', '~> 5.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
