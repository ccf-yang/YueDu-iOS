import Foundation

/// 日期工具类
class DateUtils {
    static let shared = DateUtils()
    
    private let dateFormatter = DateFormatter()
    
    /// 将日期格式化为字符串
    func format(_ date: Date, format: String = "yyyy-MM-dd HH:mm") -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    /// 将时间戳转换为日期
    func dateFromTimestamp(_ timestamp: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    /// 将日期转换为时间戳
    func timestampFromDate(_ date: Date) -> TimeInterval {
        return date.timeIntervalSince1970
    }
    
    /// 获取相对时间文本（如 "2 小时前"）
    func relativeTime(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        }
        if let month = components.month, month > 0 {
            return "\(month)个月前"
        }
        if let day = components.day, day > 0 {
            return "\(day)天前"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        }
        return "刚刚"
    }
    
    /// 判断是否是今天
    func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    /// 判断是否是昨天
    func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
}
