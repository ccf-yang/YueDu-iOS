import Foundation

class SearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var recentKeywords: [String] = []

    private let service = BookSourceService.shared
    private var searchTask: Task<Void, Never>?

    init() { loadRecentKeywords() }

    func search(keyword: String) {
        let kw = keyword.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else { searchResults = []; return }

        // 取消上一次搜索
        searchTask?.cancel()
        searchTask = Task {
            await MainActor.run { self.isSearching = true; self.errorMessage = nil }
            let sources = DatabaseService.shared.getAllBookSources(enabledOnly: true)
            guard !sources.isEmpty else {
                await MainActor.run {
                    self.isSearching = false
                    self.errorMessage = "暂无可用书源，请先在设置中添加书源"
                }
                return
            }
            let results = await service.searchBooks(keyword: kw, sources: sources)
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
                if results.isEmpty { self.errorMessage = "未找到相关书籍" }
                self.saveKeyword(kw)
            }
        }
    }

    func addToBookshelf(_ result: SearchResult) -> Bool {
        DatabaseService.shared.saveBook(result.book)
    }

    // MARK: - 最近搜索
    private func loadRecentKeywords() {
        recentKeywords = UserDefaults.standard.stringArray(forKey: "recentKeywords") ?? []
    }

    private func saveKeyword(_ kw: String) {
        recentKeywords.removeAll { $0 == kw }
        recentKeywords.insert(kw, at: 0)
        if recentKeywords.count > 10 { recentKeywords = Array(recentKeywords.prefix(10)) }
        UserDefaults.standard.set(recentKeywords, forKey: "recentKeywords")
    }

    func clearRecentKeywords() {
        recentKeywords = []
        UserDefaults.standard.removeObject(forKey: "recentKeywords")
    }
}
