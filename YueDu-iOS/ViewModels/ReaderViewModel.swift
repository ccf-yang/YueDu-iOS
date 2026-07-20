import Foundation
import Combine

class ReaderViewModel: ObservableObject {
    @Published var book: Book
    @Published var chapters: [BookChapter] = []
    @Published var currentChapter: BookChapter?
    @Published var currentContent: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var progress: Double = 0
    @Published var bookmarks: [Bookmark] = []

    // 阅读设置
    @Published var fontSize: Int = 16
    @Published var lineSpacing: CGFloat = 8
    @Published var bgColorIndex: Int = 0   // 0=白,1=护眼,2=夜间

    private(set) var currentChapterIndex: Int = 0
    private var contentCache: [String: String] = [:]
    private let db = DatabaseService.shared
    private let sourceService = BookSourceService.shared

    static let bgColors: [(name: String, bg: String, fg: String)] = [
        ("白天", "#FFFFFF", "#1C1C1E"),
        ("护眼", "#C7EDCC", "#1C1C1E"),
        ("夜间", "#1C1C1E", "#AAAAAA"),
        ("牛皮纸", "#F5DEB3", "#3E2723"),
    ]

    init(book: Book) {
        self.book = book
        self.currentChapterIndex = book.durChapterIndex
        loadReadingSettings()
    }

    // MARK: - 数据加载

    func loadChapters() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let chs = self.db.getChapters(for: self.book.id)
            DispatchQueue.main.async {
                self.chapters = chs
                if chs.isEmpty {
                    // 没有缓存章节，尝试在线获取
                    Task { await self.fetchChaptersOnline() }
                } else {
                    self.jumpToChapter(index: self.currentChapterIndex)
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchChaptersOnline() async {
        guard let source = db.getAllBookSources(enabledOnly: true)
                .first(where: { $0.bookSourceUrl == book.origin }) else {
            await MainActor.run { self.isLoading = false; self.errorMessage = "未找到对应书源" }
            return
        }
        do {
            let chs = try await sourceService.fetchChapterList(book: book, source: source)
            db.saveChapters(chs)
            await MainActor.run {
                self.chapters = chs
                self.jumpToChapter(index: self.currentChapterIndex)
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false; self.errorMessage = error.localizedDescription }
        }
    }

    func loadCurrentChapterContent() {
        guard let chapter = currentChapter else { return }
        isLoading = true
        errorMessage = nil

        // 内存缓存优先
        if let cached = contentCache[chapter.url] {
            currentContent = cached
            isLoading = false
            return
        }

        Task {
            // 本地书籍：从 DB 缓存读取
            if book.origin == "local" {
                let content = db.getCachedContent(bookUrl: book.id, chapterUrl: chapter.url) ?? "暂无内容"
                contentCache[chapter.url] = content
                await MainActor.run { self.currentContent = content; self.isLoading = false }
                return
            }
            // 网络书源：先查 DB 缓存，再抓取
            if let dbContent = db.getCachedContent(bookUrl: book.id, chapterUrl: chapter.url) {
                contentCache[chapter.url] = dbContent
                await MainActor.run { self.currentContent = dbContent; self.isLoading = false }
                return
            }
            guard let source = db.getAllBookSources(enabledOnly: true)
                    .first(where: { $0.bookSourceUrl == book.origin }) else {
                await MainActor.run { self.isLoading = false; self.errorMessage = "未找到对应书源" }
                return
            }
            do {
                let content = try await sourceService.fetchChapterContent(chapter: chapter, source: source)
                contentCache[chapter.url] = content
                await MainActor.run { self.currentContent = content; self.isLoading = false }
            } catch {
                await MainActor.run { self.isLoading = false; self.errorMessage = "加载失败: \(error.localizedDescription)" }
            }
        }
    }

    // MARK: - 章节导航

    func jumpToChapter(index: Int) {
        guard !chapters.isEmpty else { return }
        let safeIdx = max(0, min(index, chapters.count - 1))
        currentChapterIndex = safeIdx
        currentChapter = chapters[safeIdx]
        loadCurrentChapterContent()
        saveProgress()
    }

    func nextChapter() {
        guard currentChapterIndex < chapters.count - 1 else { return }
        jumpToChapter(index: currentChapterIndex + 1)
    }

    func previousChapter() {
        guard currentChapterIndex > 0 else { return }
        jumpToChapter(index: currentChapterIndex - 1)
    }

    func goToChapter(_ chapter: BookChapter) {
        if let idx = chapters.firstIndex(where: { $0.id == chapter.id }) {
            jumpToChapter(index: idx)
        }
    }

    // MARK: - 进度管理

    func saveProgress() {
        var updated = book
        updated.durChapterIndex = currentChapterIndex
        updated.durChapterTitle = currentChapter?.title
        updated.durChapterTime  = Date()
        progress = chapters.isEmpty ? 0 : Double(currentChapterIndex) / Double(chapters.count)
        db.saveBook(updated)
        book = updated
    }

    // MARK: - 字体行距

    func increaseFontSize() { if fontSize < 28 { fontSize += 1; saveReadingSettings() } }
    func decreaseFontSize() { if fontSize > 12 { fontSize -= 1; saveReadingSettings() } }

    // MARK: - 书签

    func loadBookmarks() {
        bookmarks = db.getBookmarks(for: book.id)
    }

    func addBookmark(pos: Int) {
        guard let chapter = currentChapter else { return }
        let snippet = String((currentContent ?? "").prefix(50))
        let bm = Bookmark(bookUrl: book.id, chapterIndex: currentChapterIndex,
                          chapterTitle: chapter.title, chapterPos: pos, content: snippet)
        db.saveBookmark(bm)
        loadBookmarks()
    }

    func deleteBookmark(_ bm: Bookmark) {
        db.deleteBookmark(bm.id)
        bookmarks.removeAll { $0.id == bm.id }
    }

    // MARK: - 持久化设置

    private func loadReadingSettings() {
        let d = UserDefaults.standard
        fontSize      = d.integer(forKey: "reader_fontSize").nonZero ?? 16
        lineSpacing   = CGFloat(d.double(forKey: "reader_lineSpacing")).nonZero ?? 8
        bgColorIndex  = d.integer(forKey: "reader_bgColor")
    }

    private func saveReadingSettings() {
        let d = UserDefaults.standard
        d.set(fontSize,         forKey: "reader_fontSize")
        d.set(Double(lineSpacing), forKey: "reader_lineSpacing")
        d.set(bgColorIndex,     forKey: "reader_bgColor")
    }
}

// MARK: - 辅助扩展
private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
private extension CGFloat {
    var nonZero: CGFloat? { self == 0 ? nil : self }
}
