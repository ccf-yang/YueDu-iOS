import Foundation
import SQLite3

/// 数据库服务 - 管理本地 SQLite 数据库
class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        // 获取文档目录
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        dbPath = documentsDirectory.appendingPathComponent("yuedu.db").path
    }
    
    /// 初始化数据库
    func initialize() {
        openDatabase()
        createTables()
    }
    
    /// 打开数据库
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("✅ 数据库打开成功: \(dbPath)")
        } else {
            print("❌ 数据库打开失败")
        }
    }
    
    /// 创建表
    private func createTables() {
        // 创建书籍表
        let createBooksSQL = """
        CREATE TABLE IF NOT EXISTS books (
            bookUrl TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            author TEXT NOT NULL,
            coverUrl TEXT,
            customCoverUrl TEXT,
            intro TEXT,
            customIntro TEXT,
            kind TEXT,
            customTag TEXT,
            origin TEXT DEFAULT 'local',
            originName TEXT DEFAULT '本地',
            tocUrl TEXT,
            durChapterIndex INTEGER DEFAULT 0,
            durChapterPos INTEGER DEFAULT 0,
            durChapterTitle TEXT,
            durChapterTime INTEGER DEFAULT 0,
            totalChapterNum INTEGER DEFAULT 0,
            latestChapterTitle TEXT,
            latestChapterTime INTEGER DEFAULT 0,
            wordCount TEXT,
            type INTEGER DEFAULT 0,
            group_id INTEGER DEFAULT 0,
            order_index INTEGER DEFAULT 0,
            canUpdate INTEGER DEFAULT 1,
            readConfig TEXT,
            charset TEXT,
            lastCheckTime INTEGER DEFAULT 0,
            syncTime INTEGER
        )
        """
        executeSQL(createBooksSQL)
        
        // 创建章节表
        let createChaptersSQL = """
        CREATE TABLE IF NOT EXISTS chapters (
            url TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            isVolume INTEGER DEFAULT 0,
            baseUrl TEXT,
            bookUrl TEXT NOT NULL,
            chapter_index INTEGER NOT NULL,
            isVip INTEGER DEFAULT 0,
            isPay INTEGER DEFAULT 0,
            resourceUrl TEXT,
            tag TEXT,
            wordCount TEXT,
            start_pos INTEGER,
            end_pos INTEGER,
            startFragmentId TEXT,
            endFragmentId TEXT,
            variable TEXT,
            FOREIGN KEY(bookUrl) REFERENCES books(bookUrl) ON DELETE CASCADE
        )
        """
        executeSQL(createChaptersSQL)
        
        // 创建书源表
        let createSourcesSQL = """
        CREATE TABLE IF NOT EXISTS book_sources (
            bookSourceUrl TEXT PRIMARY KEY,
            bookSourceName TEXT NOT NULL,
            bookSourceGroup TEXT,
            bookSourceType INTEGER DEFAULT 0,
            bookUrlPattern TEXT,
            customOrder INTEGER DEFAULT 0,
            enabled INTEGER DEFAULT 1,
            enabledExplore INTEGER DEFAULT 1,
            jsLib TEXT,
            enabledCookieJar INTEGER DEFAULT 1,
            concurrentRate TEXT,
            header TEXT,
            loginUrl TEXT,
            loginUi TEXT,
            loginCheckJs TEXT,
            coverDecodeJs TEXT,
            bookSourceComment TEXT,
            variableComment TEXT,
            lastUpdateTime INTEGER DEFAULT 0,
            respondTime INTEGER DEFAULT 180000,
            weight INTEGER DEFAULT 0,
            exploreUrl TEXT,
            exploreScreen TEXT,
            ruleExplore TEXT,
            ruleSearch TEXT,
            ruleBookInfo TEXT,
            ruleToc TEXT,
            ruleContent TEXT
        )
        """
        executeSQL(createSourcesSQL)
        
        print("✅ 所有表创建成功")
    }
    
    /// 执行 SQL 语句
    private func executeSQL(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let error = String(cString: errorMessage ?? "未知错误")
            print("❌ SQL 执行失败: \(error)")
            sqlite3_free(errorMessage)
        }
    }
    
    // MARK: - 书籍操作
    
    /// 保存书籍
    func saveBook(_ book: Book) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO books (
            bookUrl, name, author, coverUrl, customCoverUrl, intro, customIntro,
            kind, customTag, origin, originName, tocUrl, durChapterIndex, durChapterPos,
            durChapterTitle, durChapterTime, totalChapterNum, latestChapterTitle,
            latestChapterTime, wordCount, type, group_id, order_index, canUpdate,
            readConfig, charset, lastCheckTime, syncTime
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        let readConfigJSON = try? JSONEncoder().encode(book.readConfig)
        let readConfigString = readConfigJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "null"
        
        sqlite3_bind_text(statement, 1, book.id, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, book.name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, book.author, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, book.coverUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 5, book.customCoverUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 6, book.intro, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 7, book.customIntro, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 8, book.kind, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 9, book.customTag, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 10, book.origin, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 11, book.originName, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 12, book.tocUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 13, Int32(book.durChapterIndex))
        sqlite3_bind_int(statement, 14, Int32(book.durChapterPos))
        sqlite3_bind_text(statement, 15, book.durChapterTitle, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(statement, 16, Int64(book.durChapterTime.timeIntervalSince1970))
        sqlite3_bind_int(statement, 17, Int32(book.totalChapterNum))
        sqlite3_bind_text(statement, 18, book.latestChapterTitle, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(statement, 19, Int64(book.latestChapterTime.timeIntervalSince1970))
        sqlite3_bind_text(statement, 20, book.wordCount, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 21, Int32(book.type))
        sqlite3_bind_int(statement, 22, Int32(book.group))
        sqlite3_bind_int(statement, 23, Int32(book.order))
        sqlite3_bind_int(statement, 24, book.canUpdate ? 1 : 0)
        sqlite3_bind_text(statement, 25, readConfigString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 26, book.charset, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(statement, 27, Int64(book.lastCheckTime.timeIntervalSince1970))
        sqlite3_bind_int64(statement, 28, book.syncTime.flatMap { Int64($0.timeIntervalSince1970) } ?? 0)
        
        return sqlite3_step(statement) == SQLITE_DONE
    }
    
    /// 获取所有书籍
    func getAllBooks() -> [Book] {
        var books: [Book] = []
        let sql = "SELECT * FROM books ORDER BY order_index DESC"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            return books
        }
        
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let book = parseBook(statement: statement) {
                books.append(book)
            }
        }
        
        return books
    }
    
    /// 获取单本书籍
    func getBook(by bookUrl: String) -> Book? {
        let sql = "SELECT * FROM books WHERE bookUrl = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            return nil
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, bookUrl, -1, SQLITE_TRANSIENT)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return parseBook(statement: statement)
        }
        
        return nil
    }
    
    /// 删除书籍
    func deleteBook(_ bookUrl: String) -> Bool {
        let sql = "DELETE FROM books WHERE bookUrl = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, bookUrl, -1, SQLITE_TRANSIENT)
        
        return sqlite3_step(statement) == SQLITE_DONE
    }
    
    /// 解析书籍
    private func parseBook(statement: OpaquePointer) -> Book? {
        guard let bookUrl = String(cString: sqlite3_column_text(statement, 0)) else { return nil }
        
        let name = String(cString: sqlite3_column_text(statement, 1)) ?? ""
        let author = String(cString: sqlite3_column_text(statement, 2)) ?? ""
        let coverUrl = String(cString: sqlite3_column_text(statement, 3))
        let customCoverUrl = String(cString: sqlite3_column_text(statement, 4))
        let intro = String(cString: sqlite3_column_text(statement, 5))
        let customIntro = String(cString: sqlite3_column_text(statement, 6))
        let kind = String(cString: sqlite3_column_text(statement, 7))
        let customTag = String(cString: sqlite3_column_text(statement, 8))
        let origin = String(cString: sqlite3_column_text(statement, 9)) ?? "local"
        let originName = String(cString: sqlite3_column_text(statement, 10)) ?? "本地"
        let tocUrl = String(cString: sqlite3_column_text(statement, 11))
        
        let durChapterIndex = Int(sqlite3_column_int(statement, 12))
        let durChapterPos = Int(sqlite3_column_int(statement, 13))
        let durChapterTitle = String(cString: sqlite3_column_text(statement, 14))
        let durChapterTime = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 15)))
        let totalChapterNum = Int(sqlite3_column_int(statement, 16))
        let latestChapterTitle = String(cString: sqlite3_column_text(statement, 17))
        let latestChapterTime = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 18)))
        let wordCount = String(cString: sqlite3_column_text(statement, 19))
        let type = Int(sqlite3_column_int(statement, 20))
        let group = Int(sqlite3_column_int(statement, 21))
        let order = Int(sqlite3_column_int(statement, 22))
        let canUpdate = sqlite3_column_int(statement, 23) != 0
        let charset = String(cString: sqlite3_column_text(statement, 25))
        let lastCheckTime = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 26)))
        
        return Book(
            id: bookUrl,
            name: name,
            author: author,
            coverUrl: coverUrl,
            customCoverUrl: customCoverUrl,
            intro: intro,
            customIntro: customIntro,
            kind: kind,
            customTag: customTag,
            origin: origin,
            originName: originName,
            tocUrl: tocUrl,
            durChapterIndex: durChapterIndex,
            durChapterPos: durChapterPos,
            durChapterTitle: durChapterTitle,
            durChapterTime: durChapterTime,
            totalChapterNum: totalChapterNum,
            latestChapterTitle: latestChapterTitle,
            latestChapterTime: latestChapterTime,
            wordCount: wordCount,
            type: type,
            group: group,
            order: order,
            canUpdate: canUpdate,
            charset: charset,
            lastCheckTime: lastCheckTime
        )
    }
    
    // MARK: - 章节操作
    
    /// 保存章节
    func saveChapter(_ chapter: BookChapter) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO chapters (
            url, title, isVolume, baseUrl, bookUrl, chapter_index, isVip, isPay,
            resourceUrl, tag, wordCount, start_pos, end_pos, startFragmentId,
            endFragmentId, variable
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, chapter.url, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, chapter.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 3, chapter.isVolume ? 1 : 0)
        sqlite3_bind_text(statement, 4, chapter.baseUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 5, chapter.bookUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 6, Int32(chapter.index))
        sqlite3_bind_int(statement, 7, chapter.isVip ? 1 : 0)
        sqlite3_bind_int(statement, 8, chapter.isPay ? 1 : 0)
        sqlite3_bind_text(statement, 9, chapter.resourceUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 10, chapter.tag, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 11, chapter.wordCount, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(statement, 12, chapter.start ?? 0)
        sqlite3_bind_int64(statement, 13, chapter.end ?? 0)
        sqlite3_bind_text(statement, 14, chapter.startFragmentId, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 15, chapter.endFragmentId, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 16, chapter.variable, -1, SQLITE_TRANSIENT)
        
        return sqlite3_step(statement) == SQLITE_DONE
    }
    
    /// 获取书籍的所有章节
    func getChapters(for bookUrl: String) -> [BookChapter] {
        var chapters: [BookChapter] = []
        let sql = "SELECT * FROM chapters WHERE bookUrl = ? ORDER BY chapter_index ASC"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            return chapters
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, bookUrl, -1, SQLITE_TRANSIENT)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let chapter = parseChapter(statement: statement) {
                chapters.append(chapter)
            }
        }
        
        return chapters
    }
    
    /// 解析章节
    private func parseChapter(statement: OpaquePointer) -> BookChapter? {
        guard let url = String(cString: sqlite3_column_text(statement, 0)) else { return nil }
        
        let title = String(cString: sqlite3_column_text(statement, 1)) ?? ""
        let isVolume = sqlite3_column_int(statement, 2) != 0
        let baseUrl = String(cString: sqlite3_column_text(statement, 3)) ?? ""
        let bookUrl = String(cString: sqlite3_column_text(statement, 4)) ?? ""
        let index = Int(sqlite3_column_int(statement, 5))
        let isVip = sqlite3_column_int(statement, 6) != 0
        let isPay = sqlite3_column_int(statement, 7) != 0
        let resourceUrl = String(cString: sqlite3_column_text(statement, 8))
        let tag = String(cString: sqlite3_column_text(statement, 9))
        let wordCount = String(cString: sqlite3_column_text(statement, 10))
        let start = sqlite3_column_int64(statement, 11)
        let end = sqlite3_column_int64(statement, 12)
        let startFragmentId = String(cString: sqlite3_column_text(statement, 13))
        let endFragmentId = String(cString: sqlite3_column_text(statement, 14))
        let variable = String(cString: sqlite3_column_text(statement, 15))
        
        return BookChapter(
            url: url,
            title: title,
            bookUrl: bookUrl,
            index: index,
            isVolume: isVolume,
            baseUrl: baseUrl,
            isVip: isVip,
            isPay: isPay,
            resourceUrl: resourceUrl,
            tag: tag,
            wordCount: wordCount,
            start: start > 0 ? start : nil,
            end: end > 0 ? end : nil,
            startFragmentId: startFragmentId,
            endFragmentId: endFragmentId,
            variable: variable
        )
    }
    
    deinit {
        sqlite3_close(db)
    }
}
