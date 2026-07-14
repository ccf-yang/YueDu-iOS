import Foundation

/// 搜索服务 - 跨书源搜索
class SearchService {
    static let shared = SearchService()
    
    private let networkService = NetworkService.shared
    private let ruleEngine = RuleEngine.shared
    private let bookSourceManager = BookSourceManager.shared
    
    /// 跨书源搜索
    func searchAcrossSources(keyword: String) async -> [Book] {
        let enabledSources = bookSourceManager.getEnabledSources()
        var allResults: [Book] = []
        var searchTasks: [Task<[Book], Never>] = []
        
        // 为每个书源创建搜索任务
        for source in enabledSources {
            let task = Task { [weak self] () -> [Book] in
                return await self?.searchInSource(keyword, source: source) ?? []
            }
            searchTasks.append(task)
        }
        
        // 等待所有任务完成
        for task in searchTasks {
            let results = await task.value
            allResults.append(contentsOf: results)
        }
        
        // 去重和排序
        return deduplicateAndSort(allResults)
    }
    
    /// 在单个书源中搜索
    private func searchInSource(keyword: String, source: BookSource) async -> [Book] {
        guard let searchUrl = buildSearchURL(keyword, source: source) else {
            return []
        }
        
        do {
            let html = try await networkService.fetchHTML(url: searchUrl)
            let books = ruleEngine.parseSearchRule(html, rule: source)
            // 补充书源信息
            return books.map { book in
                var updatedBook = book
                updatedBook.originName = source.bookSourceName
                return updatedBook
            }
        } catch {
            print("❌ 在书源 \(source.bookSourceName) 中搜索失败: \(error)")
            return []
        }
    }
    
    /// 构建搜索 URL
    private func buildSearchURL(_ keyword: String, source: BookSource) -> String? {
        guard let exploreUrl = source.exploreUrl else { return nil }
        
        // 简单的 URL 模板替换
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let searchUrl = exploreUrl
            .replacingOccurrences(of: "{keyword}", with: encodedKeyword)
            .replacingOccurrences(of: "{key}", with: encodedKeyword)
        
        return searchUrl.isEmpty ? nil : searchUrl
    }
    
    /// 去重和排序搜索结果
    private func deduplicateAndSort(_ books: [Book]) -> [Book] {
        var seen = Set<String>()
        var unique: [Book] = []
        
        for book in books {
            let key = book.name + book.author // 使用书名+作者作为唯一标识
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(book)
            }
        }
        
        // 按关联度排序（这里可以添加更复杂的排序逻辑）
        return unique
    }
}
