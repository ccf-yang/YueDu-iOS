import Foundation

/// 书章数据模型
struct BookChapter: Identifiable, Codable {
    let id: String
    var url: String
    var title: String
    var isVolume: Bool
    var baseUrl: String
    var bookUrl: String
    var index: Int
    var isVip: Bool
    var isPay: Bool
    var resourceUrl: String?
    var tag: String?
    var wordCount: String?
    var start: Int64?
    var end: Int64?
    var startFragmentId: String?
    var endFragmentId: String?
    var variable: String?

    enum CodingKeys: String, CodingKey {
        // id 由 url 合成，不参与 JSON 编解码
        case id
        case url, title, isVolume, baseUrl, bookUrl, index
        case isVip, isPay, resourceUrl, tag, wordCount
        case start, end, startFragmentId, endFragmentId, variable
    }

    // 自定义解码：id 缺失时用 url 填充
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        url            = try c.decode(String.self, forKey: .url)
        id             = (try? c.decode(String.self, forKey: .id)) ?? url
        title          = try c.decodeIfPresent(String.self,  forKey: .title)          ?? ""
        isVolume       = try c.decodeIfPresent(Bool.self,    forKey: .isVolume)       ?? false
        baseUrl        = try c.decodeIfPresent(String.self,  forKey: .baseUrl)        ?? ""
        bookUrl        = try c.decodeIfPresent(String.self,  forKey: .bookUrl)        ?? ""
        index          = try c.decodeIfPresent(Int.self,     forKey: .index)          ?? 0
        isVip          = try c.decodeIfPresent(Bool.self,    forKey: .isVip)          ?? false
        isPay          = try c.decodeIfPresent(Bool.self,    forKey: .isPay)          ?? false
        resourceUrl    = try c.decodeIfPresent(String.self,  forKey: .resourceUrl)
        tag            = try c.decodeIfPresent(String.self,  forKey: .tag)
        wordCount      = try c.decodeIfPresent(String.self,  forKey: .wordCount)
        start          = try c.decodeIfPresent(Int64.self,   forKey: .start)
        end            = try c.decodeIfPresent(Int64.self,   forKey: .end)
        startFragmentId = try c.decodeIfPresent(String.self, forKey: .startFragmentId)
        endFragmentId  = try c.decodeIfPresent(String.self,  forKey: .endFragmentId)
        variable       = try c.decodeIfPresent(String.self,  forKey: .variable)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(url,             forKey: .url)
        try c.encode(title,           forKey: .title)
        try c.encode(isVolume,        forKey: .isVolume)
        try c.encode(baseUrl,         forKey: .baseUrl)
        try c.encode(bookUrl,         forKey: .bookUrl)
        try c.encode(index,           forKey: .index)
        try c.encode(isVip,           forKey: .isVip)
        try c.encode(isPay,           forKey: .isPay)
        try c.encodeIfPresent(resourceUrl,     forKey: .resourceUrl)
        try c.encodeIfPresent(tag,             forKey: .tag)
        try c.encodeIfPresent(wordCount,       forKey: .wordCount)
        try c.encodeIfPresent(start,           forKey: .start)
        try c.encodeIfPresent(end,             forKey: .end)
        try c.encodeIfPresent(startFragmentId, forKey: .startFragmentId)
        try c.encodeIfPresent(endFragmentId,   forKey: .endFragmentId)
        try c.encodeIfPresent(variable,        forKey: .variable)
    }

    init(
        url: String, title: String, bookUrl: String, index: Int,
        isVolume: Bool = false, baseUrl: String = "",
        isVip: Bool = false, isPay: Bool = false,
        resourceUrl: String? = nil, tag: String? = nil,
        wordCount: String? = nil, start: Int64? = nil, end: Int64? = nil,
        startFragmentId: String? = nil, endFragmentId: String? = nil,
        variable: String? = nil
    ) {
        self.id = url; self.url = url; self.title = title
        self.isVolume = isVolume; self.baseUrl = baseUrl
        self.bookUrl = bookUrl; self.index = index
        self.isVip = isVip; self.isPay = isPay
        self.resourceUrl = resourceUrl; self.tag = tag
        self.wordCount = wordCount; self.start = start; self.end = end
        self.startFragmentId = startFragmentId; self.endFragmentId = endFragmentId
        self.variable = variable
    }
}
