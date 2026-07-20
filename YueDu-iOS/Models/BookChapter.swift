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
        case id = "url"
        case url, title, isVolume, baseUrl, bookUrl, index
        case isVip, isPay, resourceUrl, tag, wordCount
        case start, end, startFragmentId, endFragmentId, variable
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
