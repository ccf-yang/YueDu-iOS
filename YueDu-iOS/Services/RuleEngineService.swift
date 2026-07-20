import Foundation

/// 书源规则引擎 - 完整实现
/// 支持 CSS选择器、正则、XPath、JSON路径 四种规则类型
class RuleEngine {
    static let shared = RuleEngine()
    private let htmlParser = HTMLParser.shared
    private let stringUtils = StringUtils.shared
    private let network = NetworkService.shared

    // MARK: - 搜索规则执行

    /// 执行搜索并返回书籍列表
    func executeSearch(html: String, source: BookSource) -> [Book] {
        guard let ruleJSON = source.ruleSearch,
              let rule = parseJSON(ruleJSON) as? [String: Any] else { return [] }

        // 提取书籍列表区域
        let listSelector = (rule["bookList"] as? String) ?? ""
        let bookItems = listSelector.isEmpty
            ? [html]
            : extractByRule(html, rule: listSelector, baseUrl: source.bookSourceUrl)

        return bookItems.compactMap { item in
            parseBookFromRule(item, rule: rule, source: source)
        }
    }

    private func parseBookFromRule(_ html: String, rule: [String: Any], source: BookSource) -> Book? {
        let nameR   = rule["name"]    as? String ?? ""
        let authorR = rule["author"]  as? String ?? ""
        let urlR    = rule["bookUrl"] as? String ?? ""

        let names   = extractByRule(html, rule: nameR,   baseUrl: source.bookSourceUrl)
        let authors = extractByRule(html, rule: authorR, baseUrl: source.bookSourceUrl)
        let urls    = extractByRule(html, rule: urlR,    baseUrl: source.bookSourceUrl)

        guard let name = names.first?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let url  = urls.first?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else { return nil }

        let author   = authors.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "佚名"
        let coverUrl = (rule["coverUrl"] as? String).flatMap { extractByRule(html, rule: $0, baseUrl: source.bookSourceUrl).first }
        let intro    = (rule["intro"]    as? String).flatMap { extractByRule(html, rule: $0, baseUrl: source.bookSourceUrl).first }
        let kind     = (rule["kind"]     as? String).flatMap { extractByRule(html, rule: $0, baseUrl: source.bookSourceUrl).first }

        let fullUrl = resolveURL(url, baseUrl: source.bookSourceUrl)

        return Book(
            id: fullUrl, name: stringUtils.stripHTML(name),
            author: stringUtils.stripHTML(author),
            coverUrl: coverUrl.map { resolveURL($0, baseUrl: source.bookSourceUrl) },
            intro: intro.map { stringUtils.stripHTML($0) },
            kind: kind,
            origin: source.bookSourceUrl, originName: source.bookSourceName,
            tocUrl: fullUrl
        )
    }

    // MARK: - 书籍信息规则执行

    func executeBookInfo(html: String, book: Book, source: BookSource) -> BookInfoResult {
        guard let ruleJSON = source.ruleBookInfo,
              let rule = parseJSON(ruleJSON) as? [String: Any] else {
            return BookInfoResult()
        }
        var result = BookInfoResult()
        result.name     = extractFirst(html, rule: rule["name"]     as? String, base: source.bookSourceUrl)
        result.author   = extractFirst(html, rule: rule["author"]   as? String, base: source.bookSourceUrl)
        result.intro    = extractFirst(html, rule: rule["intro"]    as? String, base: source.bookSourceUrl).map { stringUtils.stripHTML($0) }
        result.coverUrl = extractFirst(html, rule: rule["coverUrl"] as? String, base: source.bookSourceUrl)
                            .map { resolveURL($0, baseUrl: source.bookSourceUrl) }
        result.kind     = extractFirst(html, rule: rule["kind"]     as? String, base: source.bookSourceUrl)
        result.tocUrl   = extractFirst(html, rule: rule["tocUrl"]   as? String, base: source.bookSourceUrl)
                            .map { resolveURL($0, baseUrl: source.bookSourceUrl) }
        return result
    }

    // MARK: - 目录规则执行

    func executeToc(html: String, bookUrl: String, source: BookSource) -> [BookChapter] {
        guard let ruleJSON = source.ruleToc,
              let rule = parseJSON(ruleJSON) as? [String: Any] else { return [] }

        let listSelector = (rule["chapterList"] as? String) ?? ""
        let items = listSelector.isEmpty
            ? [html]
            : extractByRule(html, rule: listSelector, baseUrl: source.bookSourceUrl)

        let titleRule = rule["chapterTitle"] as? String ?? ""
        let urlRule   = rule["chapterUrl"]   as? String ?? ""
        let isVipRule = rule["isVip"]        as? String ?? ""

        // 处理反向目录
        let reversed = (rule["reversed"] as? Bool) ?? false
        let orderedItems = reversed ? items.reversed() : Array(items)

        return orderedItems.enumerated().compactMap { (idx, item) in
            let titles = extractByRule(item, rule: titleRule, baseUrl: source.bookSourceUrl)
            let urls   = extractByRule(item, rule: urlRule,   baseUrl: source.bookSourceUrl)
            guard let title = titles.first?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty,
                  let url   = urls.first?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else { return nil }
            let fullUrl = resolveURL(url, baseUrl: source.bookSourceUrl)
            let isVip = isVipRule.isEmpty ? false : !extractByRule(item, rule: isVipRule, baseUrl: source.bookSourceUrl).isEmpty
            return BookChapter(url: fullUrl, title: stringUtils.stripHTML(title),
                               bookUrl: bookUrl, index: idx, isVip: isVip)
        }
    }

    // MARK: - 内容规则执行

    func executeContent(html: String, chapter: BookChapter, source: BookSource) -> String {
        guard let ruleJSON = source.ruleContent,
              let rule = parseJSON(ruleJSON) as? [String: Any] else {
            return stringUtils.stripHTML(html)
        }

        var content = ""
        if let selector = rule["content"] as? String {
            let parts = extractByRule(html, rule: selector, baseUrl: source.bookSourceUrl)
            content = parts.joined(separator: "\n\n")
        }

        // 清理：去广告、格式化
        if let replacePattern = rule["replaceRegex"] as? String {
            content = content.replacingOccurrences(of: replacePattern, with: "", options: .regularExpression)
        }
        content = stringUtils.stripHTML(content)
        content = formatChapterContent(content)

        return content
    }

    // MARK: - 规则解析核心

    /// 通用规则提取 - 自动识别规则类型
    func extractByRule(_ html: String, rule: String, baseUrl: String) -> [String] {
        let trimmed = rule.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [html] }

        // 规则链：用 @@ 分隔多级提取
        if trimmed.contains("@@") {
            let parts = trimmed.components(separatedBy: "@@")
            var current = [html]
            for part in parts {
                current = current.flatMap { extractByRule($0, rule: part, baseUrl: baseUrl) }
            }
            return current
        }

        // 规则类型判断
        if trimmed.hasPrefix("//") || trimmed.contains("::") {
            return extractByXPath(html, xpath: trimmed)
        } else if trimmed.hasPrefix("$.") || trimmed.hasPrefix("$[") {
            return extractByJSONPath(html, path: trimmed)
        } else if trimmed.hasPrefix("/") || trimmed.contains("(?") || trimmed.hasPrefix("regex:") {
            let pattern = trimmed.hasPrefix("regex:") ? String(trimmed.dropFirst(6)) : trimmed
            return htmlParser.extractByRegex(html, pattern: pattern)
        } else {
            // CSS 选择器
            return htmlParser.extractByCSSSelector(html, selector: trimmed)
        }
    }

    private func extractFirst(_ html: String, rule: String?, base: String) -> String? {
        guard let rule = rule, !rule.isEmpty else { return nil }
        return extractByRule(html, rule: rule, baseUrl: base).first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - XPath 简化提取
    private func extractByXPath(_ html: String, xpath: String) -> [String] {
        // 将 XPath 转换为正则模式（简化实现）
        let clean = xpath.trimmingCharacters(in: .whitespacesAndNewlines)
        // 支持 //tag[@attr] //tag/text() //tag/@attr
        if clean.hasSuffix("/@src") || clean.hasSuffix("/@href") {
            let attr = clean.hasSuffix("/@src") ? "src" : "href"
            let pattern = "\(attr)=[\"']([^\"']+)[\"']"
            return htmlParser.extractByRegex(html, pattern: pattern)
        }
        if clean.hasSuffix("/text()") {
            let tag = clean.components(separatedBy: "/").dropLast().last ?? ""
            let cleanTag = tag.hasPrefix("//") ? String(tag.dropFirst(2)) : tag
            return htmlParser.extractByRegex(html, pattern: "<\(cleanTag)[^>]*>([^<]+)<")
        }
        // 通配符 - 提取标签文本
        let tagPattern = clean.components(separatedBy: "/").last ?? ""
        let cleanTag = tagPattern.hasPrefix("//") ? String(tagPattern.dropFirst(2)) : tagPattern
        if !cleanTag.isEmpty {
            return htmlParser.extractByRegex(html, pattern: "<\(cleanTag)[^>]*>([\\s\\S]*?)</\(cleanTag)>")
        }
        return []
    }

    // MARK: - JSONPath 简化提取
    private func extractByJSONPath(_ json: String, path: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) else { return [] }
        let keys = path.replacingOccurrences(of: "$.", with: "").components(separatedBy: ".")
        var current: Any = obj
        for key in keys {
            if let dict = current as? [String: Any] {
                current = dict[key] ?? ""
            } else if let arr = current as? [[String: Any]], let first = arr.first {
                current = first[key] ?? ""
            } else {
                return []
            }
        }
        if let arr = current as? [String] { return arr }
        if let arr = current as? [Any] { return arr.map { "\($0)" } }
        return ["\(current)"]
    }

    // MARK: - URL 处理

    func resolveURL(_ url: String, baseUrl: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return trimmed }
        guard let base = URL(string: baseUrl) else { return trimmed }
        if trimmed.hasPrefix("//") {
            return "\(base.scheme ?? "https"):\(trimmed)"
        }
        if trimmed.hasPrefix("/") {
            return "\(base.scheme ?? "https")://\(base.host ?? "")\(trimmed)"
        }
        return URL(string: trimmed, relativeTo: base)?.absoluteString ?? trimmed
    }

    // MARK: - 变量替换

    func replaceVariables(_ template: String, variables: [String: String]) -> String {
        var result = template
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{{" + key + "}}", with: value)
            result = result.replacingOccurrences(of: "{" + key + "}", with: value)
        }
        return result
    }

    // MARK: - 内容格式化

    private func formatChapterContent(_ content: String) -> String {
        var lines = content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        lines = lines.map { line in
            // 正文段落添加两个全角空格缩进
            line.hasPrefix("\u{3000}") ? line : "\u{3000}\u{3000}" + line
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - JSON 解析

    private func parseJSON(_ jsonStr: String) -> Any? {
        guard let data = jsonStr.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
}

/// 书籍信息解析结果
struct BookInfoResult {
    var name: String?
    var author: String?
    var intro: String?
    var coverUrl: String?
    var kind: String?
    var tocUrl: String?
}
