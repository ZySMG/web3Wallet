//
//  Date+Extensions.swift
//  Web3Wallet
//
//  Created by Zy on 2025/10/27.
//  Copyright © 2025 Web3Wallet. All rights reserved.
//

import Foundation

extension Date {
    
    /// Format as relative time display
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format as short relative time display
    var shortRelativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format as date-time string
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format as date string
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// 格式化为时间字符串
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// 格式化为 ISO 8601 字符串
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    /// 检查是否为今天
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// 检查是否为昨天
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// 检查是否为本周
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// 检查是否为今年
    var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// 获取时间戳（秒）
    var timestamp: TimeInterval {
        return timeIntervalSince1970
    }
    
    /// 获取时间戳（毫秒）
    var timestampMilliseconds: Int64 {
        return Int64(timeIntervalSince1970 * 1000)
    }
    
    /// 添加天数
    func addingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// 添加小时
    func addingHours(_ hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
    
    /// 添加分钟
    func addingMinutes(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// 添加秒
    func addingSeconds(_ seconds: Int) -> Date {
        return Calendar.current.date(byAdding: .second, value: seconds, to: self) ?? self
    }
    
    /// 获取开始时间（00:00:00）
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// 获取结束时间（23:59:59）
    var endOfDay: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components) ?? self
    }
}
