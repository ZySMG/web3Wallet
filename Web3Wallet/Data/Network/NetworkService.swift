//
//  NetworkService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

/// 网络服务协议
protocol NetworkServiceProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) -> Observable<T>
    func requestData(_ endpoint: APIEndpoint) -> Observable<Data>
}

/// 网络服务实现
class NetworkService: NetworkServiceProtocol {
    
    private let session: Session
    private let baseURL: String
    
    init(baseURL: String = "https://api.etherscan.io/api") {
        self.baseURL = baseURL
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        self.session = Session(configuration: configuration)
    }
    
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) -> Observable<T> {
        return Observable.create { observer in
            let request = self.session.request(
                self.baseURL + endpoint.path,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            
            request.responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        observer.onNext(decodedResponse)
                        observer.onCompleted()
                    } catch {
                        observer.onError(NetworkError.decodingError(error))
                    }
                case .failure(let error):
                    observer.onError(NetworkError.requestFailed(error))
                }
            }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    func requestData(_ endpoint: APIEndpoint) -> Observable<Data> {
        return Observable.create { observer in
            let request = self.session.request(
                self.baseURL + endpoint.path,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            
            request.responseData { response in
                switch response.result {
                case .success(let data):
                    observer.onNext(data)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(NetworkError.requestFailed(error))
                }
            }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
}

/// 网络错误
enum NetworkError: Error, LocalizedError {
    case requestFailed(Error)
    case decodingError(Error)
    case noAPIKey
    case rateLimited
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .noAPIKey:
            return "缺少 API Key"
        case .rateLimited:
            return "请求频率限制"
        case .networkUnavailable:
            return "网络不可用"
        }
    }
}
