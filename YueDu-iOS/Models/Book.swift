import Foundation

/// 书籍数据模型  
struct Book: Identifiable, Codable {
    let id: String
    var name: String
    var author: String
    var coverUrl: String?
    var customCoverUrl: String?
    var intro: String?
    var customIntro: String?
    var kind: String?
    var customTag: String?
    var origin: String
    var originName: String
    var tocUrl: String?
    var durChapterIndex: Int
    var durChapterPos: Int
    var durChapterTitle: String?
    var durChapterTime: Date
    var totalChapterNum: Int
    var latestChapterTitle: String?
    var latestChapterTime: Date
    var wordCount: String?
    var type: Int
    var group: Int
    var order: Int
    var canUpdate: Bool
    var readConfig: ReadConfig?
    var charset: String?
    var lastCheckTime: Date
    var syncTime: Date?

    enum CodingKeys: String, CodingKey {
        case id = "bookUrl"
        case name, author, coverUrl, customCoverUrl, intro, customIntro
        case kind, customTag, origin, originName, tocUrl
        case durChapterIndex, durChapterPos, durChapterTitle, durChapterTime
        case totalChapterNum, latestChapterTitle, latestChapterTime
        case wordCount, type, group, order, canUpdate, readConfig, charset
        case lastCheckTime, syncTime
    }

    var displayCover: String? { customCoverUrl?.isEmpty == false ? customCoverUrl : coverUrl }
    var displayIntro: String? { customIntro?.isEmpty == false ? customIntro : intro }
    var unreadChapterNum: Int { max(totalChapterNum - durChapterIndex - 1, 0) }

    init(
        id: String, name: String, author: String,
        coverUrl: String? = nil, customCoverUrl: String? = nil,
        intro: String? = nil, customIntro: String? = nil,
        kind: String? = nil, customTag: String? = nil,
        origin: String = "local", originName: String = "本地",
        tocUrl: String? = nil,
        durChapterIndex: Int = 0, durChapterPos: Int = 0,
        durChapterTitle: String? = nil, durChapterTime: Date = Date(),
        totalChapterNum: Int = 0,
        latestChapterTitle: String? = nil, latestChapterTime: Date = Date(),
        wordCount: String? = nil,
        type: Int = 0, group: Int = 0, order: Int = 0,
        canUpdate: Bool = true, readConfig: ReadConfig? = nil,
        charset: String? = nil,
        lastCheckTime: Date = Date(), syncTime: Date? = nil
    ) {
        self.id = id; self.name = name; self.author = author
        self.coverUrl = coverUrl; self.customCoverUrl = customCoverUrl
        self.intro = intro; self.customIntro = customIntro
        self.kind = kind; self.customTag = customTag
        self.origin = origin; self.originName = originName; self.tocUrl = tocUrl
        self.durChapterIndex = durChapterIndex; self.durChapterPos = durChapterPos
        self.durChapterTitle = durChapterTitle; self.durChapterTime = durChapterTime
        self.totalChapterNum = totalChapterNum
        self.latestChapterTitle = latestChapterTitle; self.latestChapterTime = latestChapterTime
        self.wordCount = wordCount; self.type = type; self.group = group; self.order = order
        self.canUpdate = canUpdate; self.readConfig = readConfig; self.charset = charset
        self.lastCheckTime = lastCheckTime; self.syncTime = syncTime
    }
}

// ReadConfig 定义在 ReadConfig.swift，此处不重复定义
