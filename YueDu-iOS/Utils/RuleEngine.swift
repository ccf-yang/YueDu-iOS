import Foundation

/// 规则引擎 - 完整实现
class RuleEngine {
    static let shared = RuleEngine()
    
    private let htmlParser = HTMLParser.shared
    private let stringUtils = StringUtils.shared
    
    // MARK: - 搜索规则解析
    
    /// 解析搜索规则并执行
    func parseSearchRule(_ html: String, rule: BookSource) -> [Book] {
        guard let ruleSearchJSON = rule.ruleSearch else { return [] }
        guard let ruleDict = parseJSON(ruleSearchJSON) as? [String: Any] else { return [] }
        
        var books: [Book] = []
        
        // 提取书籍列表容器
        if let bookListSelector = ruleDict["bookList"] as? String {
            let bookListTexts = htmlParser.extractBySelector(html, selector: bookListSelector)
            
            for bookHTML in bookListTexts {
                if let book = parseBookFromSearchRule(bookHTML, ruleDict: ruleDict, origin: rule.bookSourceUrl) {
                    books.append(book)
                }
            }
        }
        
        return books
    }
    
    /// 从搜索结果解析单本书
    private func parseBookFromSearchRule(_ html: String, ruleDict: [String: Any], origin: String) -> Book? {
        guard let nameSelector = ruleDict["name"] as? String else { return nil }
        guard let authorSelector = ruleDict["author"] as? String else { return nil }
        guard let urlSelector = ruleDict["bookUrl"] as? String else { return nil }
        
        let names = htmlParser.extractBySelector(html, selector: nameSelector)
        let authors = htmlParser.extractBySelector(html, selector: authorSelector)
        let urls = htmlParser.extractBySelector(html, selector: urlSelector)
        
        guard let name = names.first?.trimmingCharacters(in: .whitespaces),
              !name.isEmpty,
              let author = authors.first?.trimmingCharacters(in: .whitespaces),
              let bookUrl = urls.first?.trimmingCharacters(in: .whitespaces),
              !bookUrl.isEmpty else {
            return nil
        }
        
        let coverUrl = (ruleDict["coverUrl"] as? String).flatMap { selector in
            htmlParser.extractBySelector(html, selector: selector).first
        }
        
        let intro = (ruleDict["intro"] as? String).flatMap { selector in
            htmlParser.extractBySelector(html, selector: selector).first
        }
        
        return Book(
            id: bookUrl,
            name: stringUtils.stripHTML(name),
            author: stringUtils.stripHTML(author),
            coverUrl: coverUrl,
            intro: intro,
            origin: origin,
            originName: "",
            tocUrl: bookUrl
        )
    }
    
    // MARK: - 目录规则解析
    
    /// 解析目录规则
    func parseTocRule(_ html: String, rule: BookSource) -> [BookChapter] {
        guard let ruleTocJSON = rule.ruleToc else { return [] }
        guard let ruleDict = parseJSON(ruleTocJSON) as? [String: Any] else { return [] }
        
        var chapters: [BookChapter] = []
        
        // 提取章节列表容器
        if let chapterListSelector = ruleDict["chapterList"] as? String {
            let chapterTexts = htmlParser.extractBySelector(html, selector: chapterListSelector)
            
            for (index, chapterHTML) in chapterTexts.enumerated() {
                if let chapter = parseChapterFromTocRule(chapterHTML, ruleDict: ruleDict, index: index, bookUrl: "") {
                    chapters.append(chapter)
                }
            }
        }
        
        return chapters
    }
    
    /// 从目录页面解析单个章节
    private func parseChapterFromTocRule(_ html: String, ruleDict: [String: Any], index: Int, bookUrl: String) -> BookChapter? {
        guard let titleSelector = ruleDict["chapterTitle"] as? String else { return nil }
        guard let urlSelector = ruleDict["chapterUrl"] as? String else { return nil }
        
        let titles = htmlParser.extractBySelector(html, selector: titleSelector)
        let urls = htmlParser.extractBySelector(html, selector: urlSelector)
        
        guard let title = titles.first?.trimmingCharacters(in: .whitespaces),
              !title.isEmpty,
              let url = urls.first?.trimmingCharacters(in: .whitespaces),
              !url.isEmpty else {
            return nil
        }
        
        return BookChapter(
            url: url,
            title: stringUtils.stripHTML(title),
            bookUrl: bookUrl,
            index: index
        )
    }
    
    // MARK: - 内容规则解析
    
    /// 解析内容规则
    func parseContentRule(_ html: String, rule: BookSource) -> String {
        guard let ruleContentJSON = rule.ruleContent else { return "" }
        guard let ruleDict = parseJSON(ruleContentJSON) as? [String: Any] else { return "" }
        
        var content = ""
        
        // 提取内容容器
        if let contentSelector = ruleDict["content"] as? String {
            let contentTexts = htmlParser.extractBySelector(html, selector: contentSelector)
            content = contentTexts.joined(separator: "\n\n")
        }
        
        // 清理格式
        content = stringUtils.stripHTML(content)
        // 移除广告
        content = removeAdvertisements(content)
        // 处理段落
        content = formatParagraphs(content)
        
        return content
    }
    
    /// 移除广告
    private func removeAdvertisements(_ content: String) -> String {
        var result = content
        let adPatterns = [
            "<div[^>]*class=['\"]ad['\"][^>]*>[\\s\\S]*?</div>",
            "<script[^>]*>[\\s\\S]*?</script>",
            "<iframe[^>]*>[\\s\\S]*?</iframe>"
        ]
        
        for pattern in adPatterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        return result
    }
    
    /// 格式化段落
    private func formatParagraphs(_ content: String) -> String {
        // 添加段落缩进
        let lines = content.components(separatedBy: "\n")
        let formattedLines = lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "" : "\u{3000}\u{3000}" + trimmed // 添加中文两个空格缩进
        }
        return formattedLines.joined(separator: "\n")
    }
    
    // MARK: - 书籍详情规则解析
    
    /// 解析书籍信息规则
    func parseBookInfoRule(_ html: String, rule: BookSource) -> (intro: String?, cover: String?) {
        guard let ruleBookInfoJSON = rule.ruleBookInfo else { return (nil, nil) }
        guard let ruleDict = parseJSON(ruleBookInfoJSON) as? [String: Any] else { return (nil, nil) }
        
        var intro: String? = nil
        var cover: String? = nil
        
        // 提取简介
        if let introSelector = ruleDict["intro"] as? String {
            intro = htmlParser.extractBySelector(html, selector: introSelector).first
            intro = intro.map { stringUtils.stripHTML($0) }
        }
        
        // 提取封面
        if let coverSelector = ruleDict["cover"] as? String {
            cover = htmlParser.extractBySelector(html, selector: coverSelector).first
        }
        
        return (intro, cover)
    }
    
    // MARK: - 辅助方法
    
    /// 解析 JSON 字符串
    private func parseJSON(_ jsonString: String) -> Any? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
    
    /// 执行变量替换
    func replaceVariables(_ content: String, variables: [String: String]) -> String {
        var result = content
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}
