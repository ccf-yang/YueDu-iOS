import Foundation
import Combine

/// 阅读器视图模型
class ReaderViewModel: ObservableObject {
    @Published var book: Book
    @Published var chapters: [BookChapter] = []
    @Published var currentChapter: BookChapter?
    @Published var currentContent: String?
    @Published var fontSize: Int = 16 { didSet { updateContent() } }
    @Published var lineSpacing: CGFloat = 6 { didSet { updateContent() } }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var progress: Double = 0 // 阅读进度
    
    private var currentChapterIndex: Int = 0
    private var contentCache: [String: String] = [:] // 缓存章节内容
    
    init(book: Book) {
        self.book = book
        self.currentChapterIndex = book.durChapterIndex
    }
    
    /// 加载章节列表
    func loadChapters() {
        DispatchQueue.main.async {
            self.chapters = DatabaseService.shared.getChapters(for: self.book.id)
            
            if self.currentChapterIndex < self.chapters.count {
                self.currentChapter = self.chapters[self.currentChapterIndex]
            } else if !self.chapters.isEmpty {
                self.currentChapter = self.chapters[0]
                self.currentChapterIndex = 0
            }
            
            self.loadCurrentChapterContent()
        }
    }
    
    /// 加载当前章节内容
    private func loadCurrentChapterContent() {
        guard let chapter = currentChapter else { return }
        
        isLoading = true
        
        // TODO: 从数据库或网络获取章节内容
        // 这里需要实现：
        // 1. 检查本地缓存
        // 2. 如果没有，从书源下载
        // 3. 解析内容（HTML、EPUB 等）
        // 4. 存储到本地
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 模拟加载
            self.currentContent = """
            \(chapter.title)
            
            这是第 \(chapter.index + 1) 章的内容。
            
            在实际应用中，这里会显示从书源获取的真实内容。
            
            支持的格式包括：
            - 纯文本
            - HTML
            - EPUB
            - 本地 TXT 文件
            
            内容会根据阅读设置进行格式化。
            """
            self.isLoading = false
            self.updateProgress()
        }
    }
    
    /// 更新内容显示
    private func updateContent() {
        // 触发视图更新
        objectWillChange.send()
    }
    
    /// 转到下一章
    func nextChapter() {
        guard currentChapterIndex < chapters.count - 1 else { return }
        currentChapterIndex += 1
        currentChapter = chapters[currentChapterIndex]
        loadCurrentChapterContent()
        updateProgress()
    }
    
    /// 转到上一章
    func previousChapter() {
        guard currentChapterIndex > 0 else { return }
        currentChapterIndex -= 1
        currentChapter = chapters[currentChapterIndex]
        loadCurrentChapterContent()
        updateProgress()
    }
    
    /// 转到指定章节
    func goToChapter(_ chapter: BookChapter) {
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        currentChapterIndex = index
        currentChapter = chapter
        loadCurrentChapterContent()
        updateProgress()
    }
    
    /// 增加字体大小
    func increaseFontSize() {
        if fontSize < 24 {
            fontSize += 1
        }
    }
    
    /// 减小字体大小
    func decreaseFontSize() {
        if fontSize > 12 {
            fontSize -= 1
        }
    }
    
    /// 更新阅读进度
    private func updateProgress() {
        if !chapters.isEmpty {
            progress = Double(currentChapterIndex) / Double(chapters.count)
        }
        
        // 保存阅读进度到数据库
        var updatedBook = book
        updatedBook.durChapterIndex = currentChapterIndex
        updatedBook.durChapterTitle = currentChapter?.title
        updatedBook.durChapterTime = Date()
        updatedBook.durChapterPos = 0
        
        _ = DatabaseService.shared.saveBook(updatedBook)
    }
}
