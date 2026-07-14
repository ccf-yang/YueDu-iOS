import Foundation

/// 书源管理服务
class BookSourceManager: ObservableObject {
    static let shared = BookSourceManager()
    
    @Published var bookSources: [BookSource] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = DatabaseService.shared
    private let fileUtils = FileUtils.shared
    
    // MARK: - 书源操作
    
    /// 加载所有书源
    func loadBookSources() {
        isLoading = true
        DispatchQueue.global().async { [weak self] in
            // TODO: 从数据库加载书源
            let sources: [BookSource] = []
            DispatchQueue.main.async {
                self?.bookSources = sources
                self?.isLoading = false
            }
        }
    }
    
    /// 添加书源
    func addBookSource(_ source: BookSource) -> Bool {
        // TODO: 保存到数据库
        bookSources.append(source)
        return true
    }
    
    /// 删除书源
    func deleteBookSource(_ source: BookSource) -> Bool {
        // TODO: 从数据库删除
        bookSources.removeAll { $0.id == source.id }
        return true
    }
    
    /// 更新书源
    func updateBookSource(_ source: BookSource) -> Bool {
        // TODO: 更新数据库
        if let index = bookSources.firstIndex(where: { $0.id == source.id }) {
            bookSources[index] = source
            return true
        }
        return false
    }
    
    /// 启用/禁用书源
    func toggleBookSource(_ source: BookSource) {
        var updatedSource = source
        updatedSource.enabled = !updatedSource.enabled
        _ = updateBookSource(updatedSource)
    }
    
    // MARK: - 书源导入导出
    
    /// 导入书源（从 JSON 字符串）
    func importFromJSON(_ jsonString: String) -> [BookSource] {
        guard let data = jsonString.data(using: .utf8) else { return [] }
        
        do {
            if let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let decoder = JSONDecoder()
                var sources: [BookSource] = []
                
                for dict in array {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                       let source = try? decoder.decode(BookSource.self, from: jsonData) {
                        sources.append(source)
                    }
                }
                
                return sources
            }
        } catch {
            errorMessage = "JSON 解析失败: \(error.localizedDescription)"
        }
        
        return []
    }
    
    /// 导出书源为 JSON
    func exportToJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(bookSources)
            return String(data: data, encoding: .utf8)
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// 从文件导入书源
    func importFromFile(_ filePath: String) -> Bool {
        guard let jsonString = fileUtils.readString(from: filePath) else {
            errorMessage = "文件读取失败"
            return false
        }
        
        let sources = importFromJSON(jsonString)
        for source in sources {
            _ = addBookSource(source)
        }
        
        return !sources.isEmpty
    }
    
    /// 导出书源到文件
    func exportToFile(_ filePath: String) -> Bool {
        guard let jsonString = exportToJSON() else {
            errorMessage = "导出失败"
            return false
        }
        
        return fileUtils.saveString(jsonString, to: filePath)
    }
    
    // MARK: - 书源搜索和过滤
    
    /// 搜索书源
    func searchBookSources(keyword: String) -> [BookSource] {
        guard !keyword.isEmpty else { return bookSources }
        
        return bookSources.filter { source in
            source.bookSourceName.localizedCaseInsensitiveContains(keyword) ||
            source.bookSourceUrl.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    /// 按分组过滤
    func filterByGroup(_ group: String) -> [BookSource] {
        return bookSources.filter { $0.bookSourceGroup == group }
    }
    
    /// 获取所有分组
    func getAllGroups() -> [String] {
        var groups = Set<String>()
        bookSources.forEach { source in
            if let group = source.bookSourceGroup {
                groups.insert(group)
            }
        }
        return Array(groups).sorted()
    }
    
    /// 获取启用的书源
    func getEnabledSources() -> [BookSource] {
        return bookSources.filter { $0.enabled }
    }
}
