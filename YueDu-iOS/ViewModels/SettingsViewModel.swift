import Foundation

class SettingsViewModel: ObservableObject {
    @Published var bookSources: [BookSource] = []
    @Published var isLoading = false
    @Published var alertMessage: String?
    @Published var showAlert = false

    private let db = DatabaseService.shared
    private let bsService = BookSourceService.shared
    private let dmService = DataManagementService.shared

    func loadBookSources() {
        bookSources = db.getAllBookSources()
    }

    @discardableResult
    func addBookSource(_ source: BookSource) -> Bool {
        let ok = db.saveBookSource(source)
        if ok { loadBookSources() }
        return ok
    }

    @discardableResult
    func deleteBookSource(_ source: BookSource) -> Bool {
        let ok = db.deleteBookSource(source.bookSourceUrl)
        if ok { bookSources.removeAll { $0.id == source.id } }
        return ok
    }

    func toggleBookSource(_ source: BookSource, enabled: Bool) {
        db.toggleBookSource(source.bookSourceUrl, enabled: enabled)
        if let idx = bookSources.firstIndex(where: { $0.id == source.id }) {
            bookSources[idx].enabled = enabled
        }
    }

    // MARK: - 书源导入

    func importBookSourcesFromJSON(_ json: String) {
        let (ok, fail) = bsService.importBookSources(jsonString: json)
        loadBookSources()
        alertMessage = "导入成功 \(ok) 个书源" + (fail > 0 ? "，失败 \(fail) 个" : "")
        showAlert = true
    }

    func importBookSourcesFromURL(_ urlStr: String) {
        Task {
            do {
                let html = try await NetworkService.shared.get(url: urlStr)
                await MainActor.run { self.importBookSourcesFromJSON(html) }
            } catch {
                await MainActor.run {
                    self.alertMessage = "从URL导入失败: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }

    // MARK: - 数据导出

    func exportData(completion: @escaping (URL?) -> Void) {
        Task {
            let result = await dmService.exportAllData()
            await MainActor.run {
                switch result {
                case .success(let url): completion(url)
                case .failure(let err):
                    self.alertMessage = "导出失败: \(err.localizedDescription)"
                    self.showAlert = true
                    completion(nil)
                }
            }
        }
    }

    func importData(from url: URL) {
        Task {
            let result = await dmService.importAllData(from: url)
            await MainActor.run {
                if let err = result.error {
                    self.alertMessage = "导入失败: \(err)"
                } else {
                    self.alertMessage = "已导入 \(result.books) 本书籍，\(result.sources) 个书源"
                    self.loadBookSources()
                }
                self.showAlert = true
            }
        }
    }

    // MARK: - 缓存管理

    func clearCache(completion: @escaping (String) -> Void) {
        let freed = dmService.clearCache()
        completion(FileUtils.shared.formattedSize(freed))
    }

    func getCacheSize() -> String {
        FileUtils.shared.formattedSize(dmService.getCacheSize())
    }

    var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }

    var buildNumber: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
    }
}
