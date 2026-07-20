import Foundation

/// 书源爬取服务 - 封装规则引擎与网络请求
class BookSourceService {
    static let shared = BookSourceService()
    private let network = NetworkService.shared
    private let ruleEngine = RuleEngine.shared
    private let db = DatabaseService.shared

    // MARK: - 搜索

    /// 跨书源并发搜索
    func searchBooks(keyword: String, sources: [BookSource]) async -> [SearchResult] {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        // 最多并发 5 个书源，避免过载
        let activeSources = sources.filter { $0.enabled }.prefix(5)
        var allResults: [SearchResult] = []

        await withTaskGroup(of: [SearchResult].self) { group in
            for source in activeSources {
                group.addTask {
                    do {
                        return try await self.searchInSource(keyword: keyword, source: source)
                    } catch {
                        print("❌ 书源[\(source.bookSourceName)]搜索失败: \(error.localizedDescription)")
                        return []
                    }
                }
            }
            for await results in group {
                allResults.append(contentsOf: results)
            }
        }

        // 去重（相同书名+作者只保留第一个）
        var seen = Set<String>()
        let deduped = allResults.filter { result in
            let key = "\(result.book.name)_\(result.book.author)"
            return seen.insert(key).inserted
        }
        // 按相关性排序
        return deduped.sorted { $0.score > $1.score }
    }

    private func searchInSource(keyword: String, source: BookSource) async throws -> [SearchResult] {
        guard let ruleSearch = source.ruleSearch,
              let rule = parseJSON(ruleSearch) as? [String: Any],
              let searchUrlTemplate = rule["searchUrl"] as? String else { return [] }

        let searchUrl = network.buildSearchURL(template: searchUrlTemplate, keyword: keyword)
        let customHeaders = parseHeaders(source.header)
        let html = try await network.get(url: searchUrl, headers: customHeaders)
        let books = ruleEngine.executeSearch(html: html, source: source)

        return books.map { book in
            var result = SearchResult(book: book)
            // 计算相关性分数
            let nameMatch = book.name.localizedCaseInsensitiveContains(keyword)
            let authorMatch = book.author.localizedCaseInsensitiveContains(keyword)
            result.score = (nameMatch ? 10 : 0) + (authorMatch ? 5 : 0) + source.weight
            return result
        }
    }

    // MARK: - 书籍详情

    func fetchBookInfo(book: Book, source: BookSource) async throws -> Book {
        let url = book.tocUrl ?? book.id
        let headers = parseHeaders(source.header)
        let html = try await network.get(url: url, headers: headers)
        let info = ruleEngine.executeBookInfo(html: html, book: book, source: source)

        var updatedBook = book
        if let name = info.name, !name.isEmpty { updatedBook.name = name }
        if let author = info.author, !author.isEmpty { updatedBook.author = author }
        if let intro = info.intro { updatedBook.intro = intro }
        if let cover = info.coverUrl { updatedBook.coverUrl = cover }
        if let kind = info.kind { updatedBook.kind = kind }
        if let tocUrl = info.tocUrl { updatedBook.tocUrl = tocUrl }
        return updatedBook
    }

    // MARK: - 目录获取

    func fetchChapterList(book: Book, source: BookSource) async throws -> [BookChapter] {
        let tocUrl = book.tocUrl ?? book.id
        let headers = parseHeaders(source.header)
        let html = try await network.get(url: tocUrl, headers: headers)
        var chapters = ruleEngine.executeToc(html: html, bookUrl: book.id, source: source)

        // 检查是否有分页目录
        if let ruleTocJSON = source.ruleToc,
           let rule = parseJSON(ruleTocJSON) as? [String: Any],
           let nextUrlRule = rule["nextTocUrl"] as? String, !nextUrlRule.isEmpty {
            var nextUrl = ruleEngine.extractByRule(html, rule: nextUrlRule, baseUrl: tocUrl).first
            var page = 1
            while let url = nextUrl, !url.isEmpty, url != tocUrl, page < 20 {
                if let pageHtml = try? await network.get(url: url, headers: headers) {
                    let more = ruleEngine.executeToc(html: pageHtml, bookUrl: book.id, source: source)
                    chapters.append(contentsOf: more)
                    nextUrl = ruleEngine.extractByRule(pageHtml, rule: nextUrlRule, baseUrl: url).first
                } else { break }
                page += 1
            }
        }

        // 修正章节序号
        for i in chapters.indices { chapters[i].index = i }
        return chapters
    }

    // MARK: - 章节内容

    func fetchChapterContent(chapter: BookChapter, source: BookSource) async throws -> String {
        // 优先从缓存读取
        if let cached = db.getCachedContent(bookUrl: chapter.bookUrl, chapterUrl: chapter.url) {
            return cached
        }
        let headers = parseHeaders(source.header)
        let html = try await network.get(url: chapter.url, headers: headers)
        let content = ruleEngine.executeContent(html: html, chapter: chapter, source: source)

        // 写入缓存
        db.cacheChapterContent(bookUrl: chapter.bookUrl, chapterUrl: chapter.url, content: content)
        return content
    }

    // MARK: - 书源导入导出

    /// 从 JSON 字符串导入书源
    func importBookSources(jsonString: String) -> (success: Int, fail: Int) {
        guard let data = jsonString.data(using: .utf8) else { return (0, 0) }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let sources = try decoder.decode([BookSource].self, from: data)
            let count = db.saveBookSources(sources)
            return (count, sources.count - count)
        } catch {
            // 兼容阅读3书源格式
            if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var ok = 0
                for dict in array {
                    if let source = parseBookSourceFromDict(dict) {
                        if db.saveBookSource(source) { ok += 1 }
                    }
                }
                return (ok, array.count - ok)
            }
            print("❌ 书源导入失败: \(error)")
            return (0, 0)
        }
    }

    /// 导出书源为 JSON 字符串
    func exportBookSources() -> String? {
        let sources = db.getAllBookSources()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(sources) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - 辅助

    private func parseHeaders(_ headerStr: String?) -> [String: String]? {
        guard let str = headerStr, !str.isEmpty else { return nil }
        if let data = str.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            return dict
        }
        // 支持 key:value 格式
        var headers: [String: String] = [:]
        for line in str.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                headers[parts[0].trimmingCharacters(in: .whitespaces)] =
                    parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            }
        }
        return headers.isEmpty ? nil : headers
    }

    private func parseJSON(_ str: String) -> Any? {
        guard let data = str.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    /// 兼容阅读3书源 JSON 格式
    private func parseBookSourceFromDict(_ dict: [String: Any]) -> BookSource? {
        guard let url = dict["bookSourceUrl"] as? String,
              let name = dict["bookSourceName"] as? String else { return nil }

        func str(_ key: String) -> String? { dict[key] as? String }
        func int(_ key: String) -> Int { dict[key] as? Int ?? 0 }
        func bool(_ key: String, default v: Bool = true) -> Bool { dict[key] as? Bool ?? v }

        return BookSource(
            bookSourceUrl: url, bookSourceName: name,
            bookSourceGroup: str("bookSourceGroup"),
            bookSourceType: int("bookSourceType"),
            bookUrlPattern: str("bookUrlPattern"),
            customOrder: int("customOrder"),
            enabled: bool("enabled"), enabledExplore: bool("enabledExplore"),
            jsLib: str("jsLib"), enabledCookieJar: bool("enabledCookieJar"),
            concurrentRate: str("concurrentRate"), header: str("header"),
            loginUrl: str("loginUrl"), loginUi: str("loginUi"),
            loginCheckJs: str("loginCheckJs"), coverDecodeJs: str("coverDecodeJs"),
            bookSourceComment: str("bookSourceComment"), variableComment: str("variableComment"),
            ruleExplore: str("ruleExplore"), ruleSearch: str("ruleSearch"),
            ruleBookInfo: str("ruleBookInfo"), ruleToc: str("ruleToc"),
            ruleContent: str("ruleContent")
        )
    }
}
