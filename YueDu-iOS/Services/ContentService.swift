import Foundation

/// 内容服务 - 管理章节内容的获取和缓存
class ContentService {
    static let shared = ContentService()
    
    private let networkService = NetworkService.shared
    private let ruleEngine = RuleEngine.shared
    private let fileUtils = FileUtils.shared
    private let db = DatabaseService.shared
    
    private let contentCacheDir: URL
    
    init() {
        contentCacheDir = fileUtils.cachesDirectory.appendingPathComponent("content")
        fileUtils.createDirectory(contentCacheDir)
    }
    
    // MARK: - 内容获取
    
    /// 获取章节内容
    func fetchChapterContent(_ chapter: BookChapter, source: BookSource) async -> String? {
        // 1. 先检查本地缓存
        if let cachedContent = getCachedContent(chapter: chapter) {
            return cachedContent
        }
        
        // 2. 从网络获取
        guard let content = await fetchContentFromNetwork(chapter, source: source) else {
            return nil
        }
        
        // 3. 缓存内容
        cacheContent(content, chapter: chapter)
        
        return content
    }
    
    /// 从网络获取内容
    private func fetchContentFromNetwork(_ chapter: BookChapter, source: BookSource) async -> String? {
        do {
            let html = try await networkService.fetchHTML(url: chapter.url)
            let content = ruleEngine.parseContentRule(html, rule: source)
            return content.isEmpty ? nil : content
        } catch {
            print("❌ 获取章节内容失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 缓存管理
    
    /// 获取缓存的内容
    private func getCachedContent(chapter: BookChapter) -> String? {
        let cachePath = getChapterCachePath(chapter)
        return fileUtils.readString(from: cachePath)
    }
    
    /// 缓存内容
    private func cacheContent(_ content: String, chapter: BookChapter) {
        let cachePath = getChapterCachePath(chapter)
        _ = fileUtils.saveString(content, to: cachePath)
    }
    
    /// 获取章节缓存路径
    private func getChapterCachePath(_ chapter: BookChapter) -> String {
        let fileName = "\(chapter.index).txt"
        let bookDir = contentCacheDir.appendingPathComponent(chapter.bookUrl).path
        return (bookDir as NSString).appendingPathComponent(fileName)
    }
    
    /// 清除书籍的所有缓存
    func clearBookCache(bookUrl: String) -> Bool {
        let bookCacheDir = contentCacheDir.appendingPathComponent(bookUrl).path
        return fileUtils.deleteFile(bookCacheDir)
    }
    
    /// 清除所有缓存
    func clearAllCache() -> Bool {
        return fileUtils.deleteFile(contentCacheDir.path)
    }
    
    // MARK: - 批量获取
    
    /// 批量获取章节内容
    func fetchMultipleChapters(_ chapters: [BookChapter], source: BookSource) async -> [String: String] {
        var results: [String: String] = [:]
        
        for chapter in chapters {
            if let content = await fetchChapterContent(chapter, source: source) {
                results[chapter.id] = content
            }
        }
        
        return results
    }
}
