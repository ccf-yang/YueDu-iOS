import Foundation

/// 书籍数据模型 - 对应 Android 的 Book entity
struct Book: Identifiable, Codable {
    let id: String // 唯一标识，对应 bookUrl
    var name: String // 书名
    var author: String // 作者
    var coverUrl: String? // 封面 URL
    var customCoverUrl: String? // 自定义封面 URL
    var intro: String? // 简介
    var customIntro: String? // 自定义简介
    var kind: String? // 分类
    var customTag: String? // 自定义标签
    
    // 源信息
    var origin: String // 书源 URL
    var originName: String // 书源名称
    var tocUrl: String? // 目录页 URL
    
    // 阅读进度
    var durChapterIndex: Int // 当前章节索引
    var durChapterPos: Int // 当前章节位置
    var durChapterTitle: String? // 当前章节标题
    var durChapterTime: Date // 最后阅读时间
    
    // 统计信息
    var totalChapterNum: Int // 总章节数
    var latestChapterTitle: String? // 最新章节标题
    var latestChapterTime: Date // 最新章节更新时间
    var wordCount: String? // 字数
    
    // 状态
    var type: Int // 书籍类型：0-文本，1-音频，2-图片
    var group: Int // 分组ID
    var order: Int // 排序
    var canUpdate: Bool // 是否可更新
    
    // 配置
    var readConfig: ReadConfig? // 阅读配置
    var charset: String? // 字符集（本地书用）
    
    // 时间戳
    var lastCheckTime: Date // 上次检查时间
    var syncTime: Date? // 同步时间
    
    enum CodingKeys: String, CodingKey {
        case id = "bookUrl"
        case name
        case author
        case coverUrl
        case customCoverUrl
        case intro
        case customIntro
        case kind
        case customTag
        case origin
        case originName
        case tocUrl
        case durChapterIndex
        case durChapterPos
        case durChapterTitle
        case durChapterTime
        case totalChapterNum
        case latestChapterTitle
        case latestChapterTime
        case wordCount
        case type
        case group
        case order
        case canUpdate
        case readConfig
        case charset
        case lastCheckTime
        case syncTime
    }
    
    // 计算属性
    var displayCover: String? {
        customCoverUrl?.isEmpty == false ? customCoverUrl : coverUrl
    }
    
    var displayIntro: String? {
        customIntro?.isEmpty == false ? customIntro : intro
    }
    
    var unreadChapterNum: Int {
        max(totalChapterNum - durChapterIndex - 1, 0)
    }
    
    // 默认初始化
    init(
        id: String,
        name: String,
        author: String,
        coverUrl: String? = nil,
        customCoverUrl: String? = nil,
        intro: String? = nil,
        customIntro: String? = nil,
        kind: String? = nil,
        customTag: String? = nil,
        origin: String = "local",
        originName: String = "本地",
        tocUrl: String? = nil,
        durChapterIndex: Int = 0,
        durChapterPos: Int = 0,
        durChapterTitle: String? = nil,
        durChapterTime: Date = Date(),
        totalChapterNum: Int = 0,
        latestChapterTitle: String? = nil,
        latestChapterTime: Date = Date(),
        wordCount: String? = nil,
        type: Int = 0,
        group: Int = 0,
        order: Int = 0,
        canUpdate: Bool = true,
        readConfig: ReadConfig? = nil,
        charset: String? = nil,
        lastCheckTime: Date = Date(),
        syncTime: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.author = author
        self.coverUrl = coverUrl
        self.customCoverUrl = customCoverUrl
        self.intro = intro
        self.customIntro = customIntro
        self.kind = kind
        self.customTag = customTag
        self.origin = origin
        self.originName = originName
        self.tocUrl = tocUrl
        self.durChapterIndex = durChapterIndex
        self.durChapterPos = durChapterPos
        self.durChapterTitle = durChapterTitle
        self.durChapterTime = durChapterTime
        self.totalChapterNum = totalChapterNum
        self.latestChapterTitle = latestChapterTitle
        self.latestChapterTime = latestChapterTime
        self.wordCount = wordCount
        self.type = type
        self.group = group
        self.order = order
        self.canUpdate = canUpdate
        self.readConfig = readConfig
        self.charset = charset
        self.lastCheckTime = lastCheckTime
        self.syncTime = syncTime
    }
}

/// 阅读配置
struct ReadConfig: Codable {
    var reverseToc: Bool = false // 反向目录
    var pageAnim: Int? = nil // 翻页动画
    var reSegment: Bool = false // 重新分段
    var imageStyle: String? = nil // 图片样式
    var useReplaceRule: Bool? = nil // 使用替换规则
    var delTag: Int = 0 // 删除标签
    var ttsEngine: String? = nil // TTS 引擎
    var splitLongChapter: Bool = true // 分割长章节
    var readSimulating: Bool = false // 模拟阅读
    var startDate: Date? = nil // 开始日期
    var startChapter: Int? = nil // 开始章节
    var dailyChapters: Int = 3 // 每日章节数
}
