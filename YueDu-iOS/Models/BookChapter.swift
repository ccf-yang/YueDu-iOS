import Foundation

/// 书章数据模型 - 对应 Android 的 BookChapter entity
struct BookChapter: Identifiable, Codable {
    let id: String // 唯一标识，对应 url
    var url: String // 章节地址
    var title: String // 章节标题
    var isVolume: Bool // 是否是卷名
    var baseUrl: String // 用来拼接相对 url
    var bookUrl: String // 书籍 ID
    var index: Int // 章节序号
    var isVip: Bool // 是否 VIP
    var isPay: Bool // 是否已购买
    var resourceUrl: String? // 音频真实 URL
    var tag: String? // 更新时间或其他附加信息
    var wordCount: String? // 本章节字数
    var start: Int64? // 章节起始位置
    var end: Int64? // 章节终止位置
    var startFragmentId: String? // EPUB 书籍当前章节的 fragmentId
    var endFragmentId: String? // EPUB 书籍下一章节的 fragmentId
    var variable: String? // 变量
    
    enum CodingKeys: String, CodingKey {
        case id = "url"
        case url
        case title
        case isVolume
        case baseUrl
        case bookUrl
        case index
        case isVip
        case isPay
        case resourceUrl
        case tag
        case wordCount
        case start
        case end
        case startFragmentId
        case endFragmentId
        case variable
    }
    
    // 初始化
    init(
        url: String,
        title: String,
        bookUrl: String,
        index: Int,
        isVolume: Bool = false,
        baseUrl: String = "",
        isVip: Bool = false,
        isPay: Bool = false,
        resourceUrl: String? = nil,
        tag: String? = nil,
        wordCount: String? = nil,
        start: Int64? = nil,
        end: Int64? = nil,
        startFragmentId: String? = nil,
        endFragmentId: String? = nil,
        variable: String? = nil
    ) {
        self.id = url
        self.url = url
        self.title = title
        self.isVolume = isVolume
        self.baseUrl = baseUrl
        self.bookUrl = bookUrl
        self.index = index
        self.isVip = isVip
        self.isPay = isPay
        self.resourceUrl = resourceUrl
        self.tag = tag
        self.wordCount = wordCount
        self.start = start
        self.end = end
        self.startFragmentId = startFragmentId
        self.endFragmentId = endFragmentId
        self.variable = variable
    }
}
