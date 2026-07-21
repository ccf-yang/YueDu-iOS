import Foundation

/// 搜索结果模型（跨书源聚合）
struct SearchResult: Identifiable {
    let id: String
    var book: Book
    var sourceName: String
    var sourceUrl: String
    var score: Int  // 相关性分数

    init(book: Book, score: Int = 0) {
        self.id = "\(book.id)_\(book.origin)"
        self.book = book
        self.sourceName = book.originName
        self.sourceUrl = book.origin
        self.score = score
    }
}

/// 书签模型
struct Bookmark: Identifiable, Codable {
    let id: String
    var bookUrl: String
    var chapterIndex: Int
    var chapterTitle: String
    var chapterPos: Int
    var content: String       // 书签处的文字摘要
    var createTime: Date
    var note: String?         // 用户笔记

    init(bookUrl: String, chapterIndex: Int, chapterTitle: String,
         chapterPos: Int, content: String, note: String? = nil) {
        self.id = UUID().uuidString
        self.bookUrl = bookUrl
        self.chapterIndex = chapterIndex
        self.chapterTitle = chapterTitle
        self.chapterPos = chapterPos
        self.content = content
        self.createTime = Date()
        self.note = note
    }

    /// 从持久化存储恢复时使用（保留原始 id 和 createTime）
    init(id: String, bookUrl: String, chapterIndex: Int, chapterTitle: String,
         chapterPos: Int, content: String, createTime: Date, note: String? = nil) {
        self.id = id
        self.bookUrl = bookUrl
        self.chapterIndex = chapterIndex
        self.chapterTitle = chapterTitle
        self.chapterPos = chapterPos
        self.content = content
        self.createTime = createTime
        self.note = note
    }
}
