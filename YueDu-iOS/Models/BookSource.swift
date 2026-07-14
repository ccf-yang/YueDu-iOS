import Foundation

/// 书源数据模型 - 对应 Android 的 BookSource entity
struct BookSource: Identifiable, Codable {
    let id: String // 唯一标识，对应 bookSourceUrl
    var bookSourceUrl: String // 书源 URL
    var bookSourceName: String // 书源名称
    var bookSourceGroup: String? // 分组
    var bookSourceType: Int // 类型：0-文本，1-音频，2-图片，3-文件
    var bookUrlPattern: String? // 详情页 URL 正则
    var customOrder: Int // 手动排序
    var enabled: Bool // 是否启用
    var enabledExplore: Bool // 启用发现
    var jsLib: String? // JS 库
    var enabledCookieJar: Bool // 启用 Cookie 自动保存
    var concurrentRate: String? // 并发率
    var header: String? // 请求头
    var loginUrl: String? // 登录地址
    var loginUi: String? // 登录 UI
    var loginCheckJs: String? // 登录检测 JS
    var coverDecodeJs: String? // 封面解密 JS
    var bookSourceComment: String? // 注释
    var variableComment: String? // 自定义变量说明
    var lastUpdateTime: Date // 最后更新时间
    var respondTime: Int64 // 响应时间
    var weight: Int // 智能排序权重
    var exploreUrl: String? // 发现 URL
    var exploreScreen: String? // 发现筛选规则
    var ruleExplore: String? // 发现规则 JSON
    var ruleSearch: String? // 搜索规则 JSON
    var ruleBookInfo: String? // 书籍信息规则 JSON
    var ruleToc: String? // 目录规则 JSON
    var ruleContent: String? // 内容规则 JSON
    
    enum CodingKeys: String, CodingKey {
        case id = "bookSourceUrl"
        case bookSourceUrl
        case bookSourceName
        case bookSourceGroup
        case bookSourceType
        case bookUrlPattern
        case customOrder
        case enabled
        case enabledExplore
        case jsLib
        case enabledCookieJar
        case concurrentRate
        case header
        case loginUrl
        case loginUi
        case loginCheckJs
        case coverDecodeJs
        case bookSourceComment
        case variableComment
        case lastUpdateTime
        case respondTime
        case weight
        case exploreUrl
        case exploreScreen
        case ruleExplore
        case ruleSearch
        case ruleBookInfo
        case ruleToc
        case ruleContent
    }
    
    // 初始化
    init(
        bookSourceUrl: String,
        bookSourceName: String,
        bookSourceGroup: String? = nil,
        bookSourceType: Int = 0,
        bookUrlPattern: String? = nil,
        customOrder: Int = 0,
        enabled: Bool = true,
        enabledExplore: Bool = true,
        jsLib: String? = nil,
        enabledCookieJar: Bool = true,
        concurrentRate: String? = nil,
        header: String? = nil,
        loginUrl: String? = nil,
        loginUi: String? = nil,
        loginCheckJs: String? = nil,
        coverDecodeJs: String? = nil,
        bookSourceComment: String? = nil,
        variableComment: String? = nil,
        lastUpdateTime: Date = Date(),
        respondTime: Int64 = 180000,
        weight: Int = 0,
        exploreUrl: String? = nil,
        exploreScreen: String? = nil,
        ruleExplore: String? = nil,
        ruleSearch: String? = nil,
        ruleBookInfo: String? = nil,
        ruleToc: String? = nil,
        ruleContent: String? = nil
    ) {
        self.id = bookSourceUrl
        self.bookSourceUrl = bookSourceUrl
        self.bookSourceName = bookSourceName
        self.bookSourceGroup = bookSourceGroup
        self.bookSourceType = bookSourceType
        self.bookUrlPattern = bookUrlPattern
        self.customOrder = customOrder
        self.enabled = enabled
        self.enabledExplore = enabledExplore
        self.jsLib = jsLib
        self.enabledCookieJar = enabledCookieJar
        self.concurrentRate = concurrentRate
        self.header = header
        self.loginUrl = loginUrl
        self.loginUi = loginUi
        self.loginCheckJs = loginCheckJs
        self.coverDecodeJs = coverDecodeJs
        self.bookSourceComment = bookSourceComment
        self.variableComment = variableComment
        self.lastUpdateTime = lastUpdateTime
        self.respondTime = respondTime
        self.weight = weight
        self.exploreUrl = exploreUrl
        self.exploreScreen = exploreScreen
        self.ruleExplore = ruleExplore
        self.ruleSearch = ruleSearch
        self.ruleBookInfo = ruleBookInfo
        self.ruleToc = ruleToc
        self.ruleContent = ruleContent
    }
}
