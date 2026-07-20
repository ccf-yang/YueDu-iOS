import Foundation

/// 书源数据模型
struct BookSource: Identifiable, Codable {
    var id: String { bookSourceUrl }

    var bookSourceUrl: String
    var bookSourceName: String
    var bookSourceGroup: String?
    var bookSourceType: Int = 0          // 0=网站, 1=url, 2=音频
    var bookUrlPattern: String?
    var customOrder: Int = 0
    var enabled: Bool = true
    var enabledExplore: Bool = true
    var jsLib: String?
    var enabledCookieJar: Bool = true
    var concurrentRate: String?
    var header: String?
    var loginUrl: String?
    var loginUi: String?
    var loginCheckJs: String?
    var coverDecodeJs: String?
    var bookSourceComment: String?
    var variableComment: String?
    var lastUpdateTime: Date = Date()
    var respondTime: Int64 = 180000
    var weight: Int = 0

    // 发现规则
    var exploreUrl: String?
    var exploreScreen: String?
    var ruleExplore: String?

    // 搜索规则
    var ruleSearch: String?

    // 书籍信息规则
    var ruleBookInfo: String?

    // 目录规则
    var ruleToc: String?

    // 内容规则
    var ruleContent: String?

    // 显示名（书源名 + 分组）
    var displayName: String {
        if let group = bookSourceGroup, !group.isEmpty {
            return "[\(group)] \(bookSourceName)"
        }
        return bookSourceName
    }

    // 书源类型描述
    var typeDescription: String {
        switch bookSourceType {
        case 0: return "网站"
        case 1: return "URL"
        case 2: return "音频"
        default: return "未知"
        }
    }

    enum CodingKeys: String, CodingKey {
        case bookSourceUrl, bookSourceName, bookSourceGroup, bookSourceType
        case bookUrlPattern, customOrder, enabled, enabledExplore
        case jsLib, enabledCookieJar, concurrentRate, header
        case loginUrl, loginUi, loginCheckJs, coverDecodeJs
        case bookSourceComment, variableComment, lastUpdateTime
        case respondTime, weight, exploreUrl, exploreScreen
        case ruleExplore, ruleSearch, ruleBookInfo, ruleToc, ruleContent
    }
}


