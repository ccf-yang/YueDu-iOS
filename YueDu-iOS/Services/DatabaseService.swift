import Foundation
import SQLite3

// SQLITE_TRANSIENT 在 Swift 中需要手动定义（-1 转为函数指针类型）
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// 数据库服务 - 管理本地 SQLite 数据库
class DatabaseService {
    static let shared = DatabaseService()
    private var db: OpaquePointer?
    private let dbPath: String

    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        dbPath = paths[0].appendingPathComponent("yuedu.db").path
    }

    func initialize() {
        openDatabase()
        createTables()
    }

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("✅ 数据库打开成功")
            // 开启 WAL 模式提升并发性能
            executeSQL("PRAGMA journal_mode=WAL;")
            executeSQL("PRAGMA foreign_keys=ON;")
        } else {
            print("❌ 数据库打开失败")
        }
    }

    private func createTables() {
        executeSQL("""
        CREATE TABLE IF NOT EXISTS books (
            bookUrl TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            author TEXT NOT NULL,
            coverUrl TEXT, customCoverUrl TEXT,
            intro TEXT, customIntro TEXT,
            kind TEXT, customTag TEXT,
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
        """)
        executeSQL("""
        CREATE TABLE IF NOT EXISTS chapters (
            url TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            isVolume INTEGER DEFAULT 0,
            baseUrl TEXT,
            bookUrl TEXT NOT NULL,
            chapter_index INTEGER NOT NULL,
            isVip INTEGER DEFAULT 0,
            isPay INTEGER DEFAULT 0,
            resourceUrl TEXT, tag TEXT,
            wordCount TEXT,
            start_pos INTEGER, end_pos INTEGER,
            startFragmentId TEXT, endFragmentId TEXT,
            variable TEXT,
            FOREIGN KEY(bookUrl) REFERENCES books(bookUrl) ON DELETE CASCADE
        )
        """)
        executeSQL("""
        CREATE TABLE IF NOT EXISTS book_sources (
            bookSourceUrl TEXT PRIMARY KEY,
            bookSourceName TEXT NOT NULL,
            bookSourceGroup TEXT,
            bookSourceType INTEGER DEFAULT 0,
            bookUrlPattern TEXT,
            customOrder INTEGER DEFAULT 0,
            enabled INTEGER DEFAULT 1,
            enabledExplore INTEGER DEFAULT 1,
            jsLib TEXT, enabledCookieJar INTEGER DEFAULT 1,
            concurrentRate TEXT, header TEXT,
            loginUrl TEXT, loginUi TEXT,
            loginCheckJs TEXT, coverDecodeJs TEXT,
            bookSourceComment TEXT, variableComment TEXT,
            lastUpdateTime INTEGER DEFAULT 0,
            respondTime INTEGER DEFAULT 180000,
            weight INTEGER DEFAULT 0,
            exploreUrl TEXT, exploreScreen TEXT,
            ruleExplore TEXT, ruleSearch TEXT,
            ruleBookInfo TEXT, ruleToc TEXT, ruleContent TEXT
        )
        """)
        executeSQL("""
        CREATE TABLE IF NOT EXISTS bookmarks (
            id TEXT PRIMARY KEY,
            bookUrl TEXT NOT NULL,
            chapterIndex INTEGER NOT NULL,
            chapterTitle TEXT NOT NULL,
            chapterPos INTEGER DEFAULT 0,
            content TEXT,
            createTime INTEGER DEFAULT 0,
            note TEXT,
            FOREIGN KEY(bookUrl) REFERENCES books(bookUrl) ON DELETE CASCADE
        )
        """)
        executeSQL("""
        CREATE TABLE IF NOT EXISTS chapter_cache (
            id TEXT PRIMARY KEY,
            bookUrl TEXT NOT NULL,
            chapterUrl TEXT NOT NULL,
            content TEXT NOT NULL,
            cacheTime INTEGER DEFAULT 0,
            UNIQUE(bookUrl, chapterUrl)
        )
        """)
        // 创建索引提升查询速度
        executeSQL("CREATE INDEX IF NOT EXISTS idx_chapters_bookUrl ON chapters(bookUrl, chapter_index);")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_cache_bookChapter ON chapter_cache(bookUrl, chapterUrl);")
        print("✅ 所有表创建成功")
    }

    @discardableResult
    private func executeSQL(_ sql: String) -> Bool {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        if result != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "未知错误"
            print("❌ SQL 执行失败: \(error)\nSQL: \(sql)")
            sqlite3_free(errorMessage)
            return false
        }
        return true
    }

    // MARK: - 书籍操作

    @discardableResult
    func saveBook(_ book: Book) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO books (
            bookUrl,name,author,coverUrl,customCoverUrl,intro,customIntro,
            kind,customTag,origin,originName,tocUrl,
            durChapterIndex,durChapterPos,durChapterTitle,durChapterTime,
            totalChapterNum,latestChapterTitle,latestChapterTime,wordCount,
            type,group_id,order_index,canUpdate,readConfig,charset,lastCheckTime,syncTime
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }

        let rc = try? JSONEncoder().encode(book.readConfig)
        let rcStr = rc.flatMap { String(data: $0, encoding: .utf8) } ?? "null"

        sqlite3_bind_text(stmt, 1,  book.id,                              -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2,  book.name,                            -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3,  book.author,                          -1, SQLITE_TRANSIENT)
        bindOptText(stmt, 4,  book.coverUrl)
        bindOptText(stmt, 5,  book.customCoverUrl)
        bindOptText(stmt, 6,  book.intro)
        bindOptText(stmt, 7,  book.customIntro)
        bindOptText(stmt, 8,  book.kind)
        bindOptText(stmt, 9,  book.customTag)
        sqlite3_bind_text(stmt, 10, book.origin,                          -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 11, book.originName,                      -1, SQLITE_TRANSIENT)
        bindOptText(stmt, 12, book.tocUrl)
        sqlite3_bind_int(stmt,  13, Int32(book.durChapterIndex))
        sqlite3_bind_int(stmt,  14, Int32(book.durChapterPos))
        bindOptText(stmt, 15, book.durChapterTitle)
        sqlite3_bind_int64(stmt,16, Int64(book.durChapterTime.timeIntervalSince1970))
        sqlite3_bind_int(stmt,  17, Int32(book.totalChapterNum))
        bindOptText(stmt, 18, book.latestChapterTitle)
        sqlite3_bind_int64(stmt,19, Int64(book.latestChapterTime.timeIntervalSince1970))
        bindOptText(stmt, 20, book.wordCount)
        sqlite3_bind_int(stmt,  21, Int32(book.type))
        sqlite3_bind_int(stmt,  22, Int32(book.group))
        sqlite3_bind_int(stmt,  23, Int32(book.order))
        sqlite3_bind_int(stmt,  24, book.canUpdate ? 1 : 0)
        sqlite3_bind_text(stmt, 25, rcStr,                                -1, SQLITE_TRANSIENT)
        bindOptText(stmt, 26, book.charset)
        sqlite3_bind_int64(stmt,27, Int64(book.lastCheckTime.timeIntervalSince1970))
        sqlite3_bind_int64(stmt,28, book.syncTime.map { Int64($0.timeIntervalSince1970) } ?? 0)

        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func getAllBooks() -> [Book] {
        var books: [Book] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT * FROM books ORDER BY durChapterTime DESC", -1, &stmt, nil) == SQLITE_OK else { return books }
        defer { sqlite3_finalize(stmt) }
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let b = parseBook(stmt) { books.append(b) }
        }
        return books
    }

    func getBook(by bookUrl: String) -> Book? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT * FROM books WHERE bookUrl = ?", -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookUrl, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_ROW ? parseBook(stmt) : nil
    }

    @discardableResult
    func deleteBook(_ bookUrl: String) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM books WHERE bookUrl = ?", -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookUrl, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    private func parseBook(_ stmt: OpaquePointer?) -> Book? {
        guard let stmt = stmt else { return nil }
        let bookUrl  = colText(stmt, 0) ?? ""; guard !bookUrl.isEmpty else { return nil }
        let name     = colText(stmt, 1) ?? ""
        let author   = colText(stmt, 2) ?? ""
        let coverUrl = colText(stmt, 3)
        let customCoverUrl = colText(stmt, 4)
        let intro    = colText(stmt, 5)
        let customIntro = colText(stmt, 6)
        let kind     = colText(stmt, 7)
        let customTag = colText(stmt, 8)
        let origin   = colText(stmt, 9) ?? "local"
        let originName = colText(stmt, 10) ?? "本地"
        let tocUrl   = colText(stmt, 11)
        let durChIdx = Int(sqlite3_column_int(stmt, 12))
        let durChPos = Int(sqlite3_column_int(stmt, 13))
        let durChTitle = colText(stmt, 14)
        let durChTime  = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(stmt, 15)))
        let totalCh  = Int(sqlite3_column_int(stmt, 16))
        let latestChTitle = colText(stmt, 17)
        let latestChTime  = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(stmt, 18)))
        let wordCount = colText(stmt, 19)
        let type     = Int(sqlite3_column_int(stmt, 20))
        let group    = Int(sqlite3_column_int(stmt, 21))
        let order    = Int(sqlite3_column_int(stmt, 22))
        let canUpdate = sqlite3_column_int(stmt, 23) != 0
        let rcStr    = colText(stmt, 24)
        let charset  = colText(stmt, 25)
        let lastCheck = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(stmt, 26)))
        let syncTs    = sqlite3_column_int64(stmt, 27)
        let syncTime  = syncTs > 0 ? Date(timeIntervalSince1970: TimeInterval(syncTs)) : nil
        var readConfig: ReadConfig? = nil
        if let rcStr = rcStr, let data = rcStr.data(using: .utf8) {
            readConfig = try? JSONDecoder().decode(ReadConfig.self, from: data)
        }
        return Book(id: bookUrl, name: name, author: author,
                    coverUrl: coverUrl, customCoverUrl: customCoverUrl,
                    intro: intro, customIntro: customIntro,
                    kind: kind, customTag: customTag,
                    origin: origin, originName: originName, tocUrl: tocUrl,
                    durChapterIndex: durChIdx, durChapterPos: durChPos,
                    durChapterTitle: durChTitle, durChapterTime: durChTime,
                    totalChapterNum: totalCh,
                    latestChapterTitle: latestChTitle, latestChapterTime: latestChTime,
                    wordCount: wordCount, type: type, group: group, order: order,
                    canUpdate: canUpdate, readConfig: readConfig, charset: charset,
                    lastCheckTime: lastCheck, syncTime: syncTime)
    }

    // MARK: - 章节操作

    @discardableResult
    func saveChapter(_ chapter: BookChapter) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO chapters
        (url,title,isVolume,baseUrl,bookUrl,chapter_index,isVip,isPay,
         resourceUrl,tag,wordCount,start_pos,end_pos,startFragmentId,endFragmentId,variable)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, chapter.url,     -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, chapter.title,   -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt,  3, chapter.isVolume ? 1 : 0)
        sqlite3_bind_text(stmt, 4, chapter.baseUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 5, chapter.bookUrl, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt,  6, Int32(chapter.index))
        sqlite3_bind_int(stmt,  7, chapter.isVip ? 1 : 0)
        sqlite3_bind_int(stmt,  8, chapter.isPay ? 1 : 0)
        bindOptText(stmt, 9,  chapter.resourceUrl)
        bindOptText(stmt, 10, chapter.tag)
        bindOptText(stmt, 11, chapter.wordCount)
        sqlite3_bind_int64(stmt, 12, chapter.start ?? 0)
        sqlite3_bind_int64(stmt, 13, chapter.end ?? 0)
        bindOptText(stmt, 14, chapter.startFragmentId)
        bindOptText(stmt, 15, chapter.endFragmentId)
        bindOptText(stmt, 16, chapter.variable)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    @discardableResult
    func saveChapters(_ chapters: [BookChapter]) -> Bool {
        executeSQL("BEGIN TRANSACTION;")
        var allOk = true
        for ch in chapters { if !saveChapter(ch) { allOk = false } }
        executeSQL(allOk ? "COMMIT;" : "ROLLBACK;")
        return allOk
    }

    func getChapters(for bookUrl: String) -> [BookChapter] {
        var chapters: [BookChapter] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db,
            "SELECT * FROM chapters WHERE bookUrl=? ORDER BY chapter_index ASC",
            -1, &stmt, nil) == SQLITE_OK else { return chapters }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookUrl, -1, SQLITE_TRANSIENT)
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let ch = parseChapter(stmt) { chapters.append(ch) }
        }
        return chapters
    }

    func getChapter(url: String) -> BookChapter? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT * FROM chapters WHERE url=?", -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, url, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_ROW ? parseChapter(stmt) : nil
    }

    @discardableResult
    func deleteChapters(for bookUrl: String) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM chapters WHERE bookUrl=?", -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookUrl, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    private func parseChapter(_ stmt: OpaquePointer?) -> BookChapter? {
        guard let stmt = stmt else { return nil }
        let url   = colText(stmt, 0) ?? ""; guard !url.isEmpty else { return nil }
        let title = colText(stmt, 1) ?? ""
        let isVol = sqlite3_column_int(stmt, 2) != 0
        let base  = colText(stmt, 3) ?? ""
        let bookUrl = colText(stmt, 4) ?? ""
        let index = Int(sqlite3_column_int(stmt, 5))
        let isVip = sqlite3_column_int(stmt, 6) != 0
        let isPay = sqlite3_column_int(stmt, 7) != 0
        let resUrl = colText(stmt, 8)
        let tag    = colText(stmt, 9)
        let wc     = colText(stmt, 10)
        let start  = sqlite3_column_int64(stmt, 11)
        let end    = sqlite3_column_int64(stmt, 12)
        let sfId   = colText(stmt, 13)
        let efId   = colText(stmt, 14)
        let variable = colText(stmt, 15)
        return BookChapter(url: url, title: title, bookUrl: bookUrl, index: index,
                           isVolume: isVol, baseUrl: base, isVip: isVip, isPay: isPay,
                           resourceUrl: resUrl, tag: tag, wordCount: wc,
                           start: start > 0 ? start : nil,
                           end: end > 0 ? end : nil,
                           startFragmentId: sfId, endFragmentId: efId, variable: variable)
    }

    // MARK: - 书源操作

    @discardableResult
    func saveBookSource(_ source: BookSource) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO book_sources
        (bookSourceUrl,bookSourceName,bookSourceGroup,bookSourceType,bookUrlPattern,
         customOrder,enabled,enabledExplore,jsLib,enabledCookieJar,
         concurrentRate,header,loginUrl,loginUi,loginCheckJs,coverDecodeJs,
         bookSourceComment,variableComment,lastUpdateTime,respondTime,weight,
         exploreUrl,exploreScreen,ruleExplore,ruleSearch,ruleBookInfo,ruleToc,ruleContent)
        VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1,  source.bookSourceUrl,  -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2,  source.bookSourceName, -1, SQLITE_TRANSIENT)
        bindOptText(stmt, 3,  source.bookSourceGroup)
        sqlite3_bind_int(stmt,  4,  Int32(source.bookSourceType))
        bindOptText(stmt, 5,  source.bookUrlPattern)
        sqlite3_bind_int(stmt,  6,  Int32(source.customOrder))
        sqlite3_bind_int(stmt,  7,  source.enabled ? 1 : 0)
        sqlite3_bind_int(stmt,  8,  source.enabledExplore ? 1 : 0)
        bindOptText(stmt, 9,  source.jsLib)
        sqlite3_bind_int(stmt,  10, source.enabledCookieJar ? 1 : 0)
        bindOptText(stmt, 11, source.concurrentRate)
        bindOptText(stmt, 12, source.header)
        bindOptText(stmt, 13, source.loginUrl)
        bindOptText(stmt, 14, source.loginUi)
        bindOptText(stmt, 15, source.loginCheckJs)
        bindOptText(stmt, 16, source.coverDecodeJs)
        bindOptText(stmt, 17, source.bookSourceComment)
        bindOptText(stmt, 18, source.variableComment)
        sqlite3_bind_int64(stmt, 19, Int64(source.lastUpdateTime.timeIntervalSince1970))
        sqlite3_bind_int64(stmt, 20, source.respondTime)
        sqlite3_bind_int(stmt,  21, Int32(source.weight))
        bindOptText(stmt, 22, source.exploreUrl)
        bindOptText(stmt, 23, source.exploreScreen)
        bindOptText(stmt, 24, source.ruleExplore)
        bindOptText(stmt, 25, source.ruleSearch)
        bindOptText(stmt, 26, source.ruleBookInfo)
        bindOptText(stmt, 27, source.ruleToc)
        bindOptText(stmt, 28, source.ruleContent)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    @discardableResult
    func saveBookSources(_ sources: [BookSource]) -> Int {
        executeSQL("BEGIN TRANSACTION;")
        var count = 0
        for s in sources { if saveBookSource(s) { count += 1 } }
        executeSQL("COMMIT;")
        return count
    }

    func getAllBookSources(enabledOnly: Bool = false) -> [BookSource] {
        var sources: [BookSource] = []
        let sql = enabledOnly
            ? "SELECT * FROM book_sources WHERE enabled=1 ORDER BY customOrder ASC, weight DESC"
            : "SELECT * FROM book_sources ORDER BY customOrder ASC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return sources }
        defer { sqlite3_finalize(stmt) }
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let s = parseBookSource(stmt) { sources.append(s) }
        }
        return sources
    }

    @discardableResult
    func deleteBookSource(_ url: String) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM book_sources WHERE bookSourceUrl=?", -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, url, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    @discardableResult
    func toggleBookSource(_ url: String, enabled: Bool) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "UPDATE book_sources SET enabled=? WHERE bookSourceUrl=?", -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, enabled ? 1 : 0)
        sqlite3_bind_text(stmt, 2, url, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    private func parseBookSource(_ stmt: OpaquePointer?) -> BookSource? {
        guard let stmt = stmt else { return nil }
        let url  = colText(stmt, 0) ?? ""; guard !url.isEmpty else { return nil }
        let name = colText(stmt, 1) ?? ""
        return BookSource(
            bookSourceUrl: url, bookSourceName: name,
            bookSourceGroup: colText(stmt, 2),
            bookSourceType: Int(sqlite3_column_int(stmt, 3)),
            bookUrlPattern: colText(stmt, 4),
            customOrder: Int(sqlite3_column_int(stmt, 5)),
            enabled: sqlite3_column_int(stmt, 6) != 0,
            enabledExplore: sqlite3_column_int(stmt, 7) != 0,
            jsLib: colText(stmt, 8),
            enabledCookieJar: sqlite3_column_int(stmt, 9) != 0,
            concurrentRate: colText(stmt, 10),
            header: colText(stmt, 11),
            loginUrl: colText(stmt, 12), loginUi: colText(stmt, 13),
            loginCheckJs: colText(stmt, 14), coverDecodeJs: colText(stmt, 15),
            bookSourceComment: colText(stmt, 16), variableComment: colText(stmt, 17),
            lastUpdateTime: Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(stmt, 18))),
            respondTime: sqlite3_column_int64(stmt, 19),
            weight: Int(sqlite3_column_int(stmt, 20)),
            exploreUrl: colText(stmt, 21), exploreScreen: colText(stmt, 22),
            ruleExplore: colText(stmt, 23), ruleSearch: colText(stmt, 24),
            ruleBookInfo: colText(stmt, 25), ruleToc: colText(stmt, 26),
            ruleContent: colText(stmt, 27)
        )
    }

    // MARK: - 章节内容缓存

    @discardableResult
    func cacheChapterContent(bookUrl: String, chapterUrl: String, content: String) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO chapter_cache (id,bookUrl,chapterUrl,content,cacheTime)
        VALUES(?,?,?,?,?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        let cid = "\(bookUrl)_\(chapterUrl)".md5
        sqlite3_bind_text(stmt, 1, cid,        -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, bookUrl,     -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, chapterUrl,  -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 4, content,     -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt, 5, Int64(Date().timeIntervalSince1970))
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func getCachedContent(bookUrl: String, chapterUrl: String) -> String? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db,
            "SELECT content FROM chapter_cache WHERE bookUrl=? AND chapterUrl=?",
            -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookUrl,    -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, chapterUrl, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_ROW ? colText(stmt, 0) : nil
    }

    func clearChapterCache(bookUrl: String) {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM chapter_cache WHERE bookUrl=?", -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookUrl, -1, SQLITE_TRANSIENT)
        sqlite3_step(stmt)
    }

    // MARK: - 书签操作

    @discardableResult
    func saveBookmark(_ bm: Bookmark) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO bookmarks
        (id,bookUrl,chapterIndex,chapterTitle,chapterPos,content,createTime,note)
        VALUES(?,?,?,?,?,?,?,?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bm.id,           -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, bm.bookUrl,      -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt,  3, Int32(bm.chapterIndex))
        sqlite3_bind_text(stmt, 4, bm.chapterTitle, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt,  5, Int32(bm.chapterPos))
        sqlite3_bind_text(stmt, 6, bm.content,      -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt,7, Int64(bm.createTime.timeIntervalSince1970))
        bindOptText(stmt, 8, bm.note)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func getBookmarks(for bookUrl: String) -> [Bookmark] {
        var bms: [Bookmark] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db,
            "SELECT * FROM bookmarks WHERE bookUrl=? ORDER BY chapterIndex,chapterPos",
            -1, &stmt, nil) == SQLITE_OK else { return bms }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, bookUrl, -1, SQLITE_TRANSIENT)
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id  = colText(stmt, 0) ?? UUID().uuidString
            let bUrl = colText(stmt, 1) ?? ""
            let ci  = Int(sqlite3_column_int(stmt, 2))
            let ct  = colText(stmt, 3) ?? ""
            let cp  = Int(sqlite3_column_int(stmt, 4))
            let content = colText(stmt, 5) ?? ""
            let time = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(stmt, 6)))
            let note = colText(stmt, 7)
            var bm = Bookmark(bookUrl: bUrl, chapterIndex: ci, chapterTitle: ct, chapterPos: cp, content: content, note: note)
            // 用数据库中存储的 id 和 createTime 覆盖构造器生成的默认值
            bm = Bookmark(id: id, bookUrl: bUrl, chapterIndex: ci, chapterTitle: ct,
                          chapterPos: cp, content: content, createTime: time, note: note)
            bms.append(bm)
        }
        return bms
    }

    @discardableResult
    func deleteBookmark(_ id: String) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM bookmarks WHERE id=?", -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, id, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    // MARK: - 辅助

    private func colText(_ stmt: OpaquePointer?, _ col: Int32) -> String? {
        guard let stmt = stmt, let cstr = sqlite3_column_text(stmt, col) else { return nil }
        return String(cString: cstr)
    }

    private func bindOptText(_ stmt: OpaquePointer?, _ col: Int32, _ value: String?) {
        if let v = value {
            sqlite3_bind_text(stmt, col, v, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, col)
        }
    }
}

// MARK: - MD5 辅助
import CryptoKit
extension String {
    var md5: String {
        let digest = Insecure.MD5.hash(data: Data(utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
