import Foundation

class DateUtils {
    static let shared = DateUtils()
    private let formatter = DateFormatter()

    func format(_ date: Date, format: String = "yyyy-MM-dd HH:mm") -> String {
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    func relativeTime(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date, to: Date())
        if let y = c.year,  y > 0 { return "\(y)年前" }
        if let mo = c.month, mo > 0 { return "\(mo)个月前" }
        if let d = c.day,   d > 0 { return "\(d)天前" }
        if let h = c.hour,  h > 0 { return "\(h)小时前" }
        if let m = c.minute, m > 0 { return "\(m)分钟前" }
        return "刚刚"
    }

    func isToday(_ date: Date) -> Bool { Calendar.current.isDateInToday(date) }
    func isYesterday(_ date: Date) -> Bool { Calendar.current.isDateInYesterday(date) }
    func dateFromTimestamp(_ ts: TimeInterval) -> Date { Date(timeIntervalSince1970: ts) }
}
