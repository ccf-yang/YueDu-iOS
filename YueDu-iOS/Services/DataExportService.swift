import Foundation

/// 数据导入导出服务
class DataExportService {
    static let shared = DataExportService()
    
    private let db = DatabaseService.shared
    private let fileUtils = FileUtils.shared
    private let bookSourceManager = BookSourceManager.shared
    
    // MARK: - 导出功能
    
    /// 导出所有数据为 JSON
    func exportAllData() -> String? {
        let books = db.getAllBooks()
        
        let exportData: [String: Any] = [
            "version": "1.0",
            "exportDate": DateUtils.shared.format(Date()),
            "books": books.map { encodeBook($0) },
            "bookSources": bookSourceManager.bookSources.map { encodeBookSource($0) }
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ 导出数据失败: \(error)")
            return nil
        }
    }
    
    /// 导出数据到文件
    func exportToFile(_ filePath: String) -> Bool {
        guard let jsonString = exportAllData() else {
            return false
        }
        
        return fileUtils.saveString(jsonString, to: filePath)
    }
    
    /// 导出单本书籍的阅读进度
    func exportBookProgress(_ book: Book) -> String? {
        let progress: [String: Any] = [
            "bookName": book.name,
            "bookAuthor": book.author,
            "currentChapter": book.durChapterIndex,
            "currentPosition": book.durChapterPos,
            "lastReadTime": DateUtils.shared.format(book.durChapterTime)
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: progress, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    // MARK: - 导入功能
    
    /// 从文件导入数据
    func importFromFile(_ filePath: String) -> Bool {
        guard let jsonString = fileUtils.readString(from: filePath) else {
            return false
        }
        
        return importFromJSON(jsonString)
    }
    
    /// 从 JSON 导入数据
    func importFromJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            return false
        }
        
        do {
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            
            // 导入书籍
            if let booksData = dict["books"] as? [[String: Any]] {
                for bookDict in booksData {
                    if let book = decodeBook(from: bookDict) {
                        _ = db.saveBook(book)
                    }
                }
            }
            
            // 导入书源
            if let sourcesData = dict["bookSources"] as? [[String: Any]] {
                for sourceDict in sourcesData {
                    if let source = decodeBookSource(from: sourceDict) {
                        _ = bookSourceManager.addBookSource(source)
                    }
                }
            }
            
            return true
        } catch {
            print("❌ 导入数据失败: \(error)")
            return false
        }
    }
    
    // MARK: - 辅助方法
    
    /// 编码书籍
    private func encodeBook(_ book: Book) -> [String: Any] {
        return [
            "id": book.id,
            "name": book.name,
            "author": book.author,
            "coverUrl": book.coverUrl ?? "",
            "intro": book.intro ?? "",
            "origin": book.origin,
            "originName": book.originName,
            "durChapterIndex": book.durChapterIndex,
            "durChapterPos": book.durChapterPos,
            "totalChapterNum": book.totalChapterNum,
            "durChapterTime": Int(book.durChapterTime.timeIntervalSince1970)
        ]
    }
    
    /// 解码书籍
    private func decodeBook(from dict: [String: Any]) -> Book? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let author = dict["author"] as? String else {
            return nil
        }
        
        return Book(
            id: id,
            name: name,
            author: author,
            coverUrl: dict["coverUrl"] as? String,
            intro: dict["intro"] as? String,
            origin: dict["origin"] as? String ?? "local",
            originName: dict["originName"] as? String ?? "",
            durChapterIndex: (dict["durChapterIndex"] as? Int) ?? 0,
            durChapterPos: (dict["durChapterPos"] as? Int) ?? 0,
            totalChapterNum: (dict["totalChapterNum"] as? Int) ?? 0
        )
    }
    
    /// 编码书源
    private func encodeBookSource(_ source: BookSource) -> [String: Any] {
        return [
            "id": source.id,
            "bookSourceName": source.bookSourceName,
            "bookSourceUrl": source.bookSourceUrl,
            "bookSourceGroup": source.bookSourceGroup ?? "",
            "enabled": source.enabled
        ]
    }
    
    /// 解码书源
    private func decodeBookSource(from dict: [String: Any]) -> BookSource? {
        guard let id = dict["id"] as? String,
              let name = dict["bookSourceName"] as? String else {
            return nil
        }
        
        return BookSource(
            bookSourceUrl: id,
            bookSourceName: name,
            bookSourceGroup: dict["bookSourceGroup"] as? String,
            enabled: (dict["enabled"] as? Bool) ?? true
        )
    }
}
