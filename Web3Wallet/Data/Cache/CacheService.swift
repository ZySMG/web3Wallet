//
//  CacheService.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

/// Cache item
struct CacheItem<T: Codable> {
    let value: T
    let timestamp: Date
    let ttl: TimeInterval
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

/// Cache service protocol
protocol CacheServiceProtocol {
    func set<T: Codable>(key: String, value: T, ttl: TimeInterval)
    func get<T: Codable>(key: String, type: T.Type) -> T?
    func get<T: Codable>(key: String) -> T?
    func delete(key: String)
    func clear()
    func exists(key: String) -> Bool
}

/// Cache service implementation
class CacheService: CacheServiceProtocol {
    
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "cache.queue", attributes: .concurrent)
    
    func set<T: Codable>(key: String, value: T, ttl: TimeInterval) {
        queue.async(flags: .barrier) {
            let cacheItem = CacheItem(value: value, timestamp: Date(), ttl: ttl)
            self.cache[key] = cacheItem
        }
    }
    
    func get<T: Codable>(key: String, type: T.Type) -> T? {
        return queue.sync {
            guard let cacheItem = cache[key] as? CacheItem<T> else { return nil }
            
            if cacheItem.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return cacheItem.value
        }
    }
    
    func get<T: Codable>(key: String) -> T? {
        return queue.sync {
            guard let cacheItem = cache[key] as? CacheItem<T> else { return nil }
            
            if cacheItem.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return cacheItem.value
        }
    }
    
    func delete(key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    func exists(key: String) -> Bool {
        return queue.sync {
            guard let cacheItem = cache[key] as? CacheItem<Data> else { return false }
            
            if cacheItem.isExpired {
                cache.removeValue(forKey: key)
                return false
            }
            
            return true
        }
    }
    
    /// Clean expired cache items
    func cleanupExpiredItems() {
        queue.async(flags: .barrier) {
            let now = Date()
            self.cache = self.cache.filter { (_, value) in
                if let cacheItem = value as? CacheItem<Data> {
                    return now.timeIntervalSince(cacheItem.timestamp) <= cacheItem.ttl
                }
                return true
            }
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> (count: Int, size: Int) {
        return queue.sync {
            let count = cache.count
            let size = MemoryLayout.size(ofValue: cache)
            return (count: count, size: size)
        }
    }
}

/// Cache key constants
struct CacheKeys {
    static let balancePrefix = "balance_"
    static let pricePrefix = "price_"
    static let txPrefix = "tx_"
    static let tokenInfoPrefix = "token_info_"
    
    static func balanceKey(address: String, currency: String, networkId: Int) -> String {
        return "\(balancePrefix)\(address)_\(currency)_\(networkId)"
    }
    
    static func priceKey(currency: String) -> String {
        return "\(pricePrefix)\(currency)"
    }
    
    static func txKey(address: String, networkId: Int, limit: Int) -> String {
        return "\(txPrefix)\(address)_\(networkId)_\(limit)"
    }
    
    static func tokenInfoKey(address: String, networkId: Int) -> String {
        return "\(tokenInfoPrefix)\(address)_\(networkId)"
    }
}
