import Foundation

/// 数据导入导出服务
class DataManagementService {
    static let shared = DataManagementService()
    private let db = DatabaseService.shared

    // MARK: - 全量导出

    struct ExportData: Codable {
        var version: Int = 2
        var exportTime: Date = Date()
        var books: [Book]
        var bookSources: [BookSource]
        var bookmarks: [Bookmark]
    }

    func exportAllData() async -> Result<URL, Error> {
        let books       = db.getAllBooks()
        let sources     = db.getAllBookSources()
        let bookmarks   = books.flatMap { db.getBookmarks(for: $0.id) }

        let exportData  = ExportData(books: books, bookSources: sources, bookmarks: bookmarks)
        let encoder     = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .millisecondsSince1970

        do {
            let data = try encoder.encode(exportData)
            let filename = "yuedu_backup_\(Int(Date().timeIntervalSince1970)).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url)
            return .success(url)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 全量导入

    func importAllData(from url: URL) async -> (books: Int, sources: Int, error: String?) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let exportData = try decoder.decode(ExportData.self, from: data)

            var bookCount = 0
            for book in exportData.books {
                if db.saveBook(book) { bookCount += 1 }
            }
            let sourceCount = db.saveBookSources(exportData.bookSources)
            for bm in exportData.bookmarks { db.saveBookmark(bm) }

            return (bookCount, sourceCount, nil)
        } catch {
            return (0, 0, error.localizedDescription)
        }
    }

    // MARK: - 书源专项导出

    func exportBookSources() async -> Result<URL, Error> {
        let sources = db.getAllBookSources()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        do {
            let data = try encoder.encode(sources)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("book_sources_\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url)
            return .success(url)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 缓存清理

    func clearCache() -> Int64 {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        var freedBytes: Int64 = 0
        if let contents = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in contents {
                if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    freedBytes += Int64(size)
                }
                try? FileManager.default.removeItem(at: file)
            }
        }
        return freedBytes
    }

    func getCacheSize() -> Int64 {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        var total: Int64 = 0
        if let contents = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in contents {
                if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    total += Int64(size)
                }
            }
        }
        return total
    }
}
