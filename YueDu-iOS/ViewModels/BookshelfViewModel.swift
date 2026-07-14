import Foundation

/// 书架视图模型
class BookshelfViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var sortBy: SortOption = .recent // 排序方式
    
    enum SortOption: String, CaseIterable {
        case recent = "最近阅读"
        case name = "书名"
        case author = "作者"
        case updateTime = "更新时间"
    }
    
    /// 加载书籍
    func loadBooks() {
        isLoading = true
        
        DispatchQueue.main.async {
            self.books = DatabaseService.shared.getAllBooks()
            self.sortBooks()
            self.isLoading = false
        }
    }
    
    /// 添加书籍
    func addBook(_ book: Book) -> Bool {
        let success = DatabaseService.shared.saveBook(book)
        if success {
            loadBooks()
        } else {
            errorMessage = "添加书籍失败"
        }
        return success
    }
    
    /// 删除书籍
    func deleteBook(_ book: Book) -> Bool {
        let success = DatabaseService.shared.deleteBook(book.id)
        if success {
            loadBooks()
        } else {
            errorMessage = "删除书籍失败"
        }
        return success
    }
    
    /// 更新书籍
    func updateBook(_ book: Book) -> Bool {
        let success = DatabaseService.shared.saveBook(book)
        if success {
            loadBooks()
        } else {
            errorMessage = "更新书籍失败"
        }
        return success
    }
    
    /// 排序书籍
    func sortBooks() {
        switch sortBy {
        case .recent:
            books.sort { $0.durChapterTime > $1.durChapterTime }
        case .name:
            books.sort { $0.name < $1.name }
        case .author:
            books.sort { $0.author < $1.author }
        case .updateTime:
            books.sort { $0.latestChapterTime > $1.latestChapterTime }
        }
    }
    
    /// 搜索书籍
    func searchBooks(keyword: String) -> [Book] {
        guard !keyword.isEmpty else { return books }
        
        return books.filter { book in
            book.name.localizedCaseInsensitiveContains(keyword) ||
            book.author.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    /// 按分组过滤
    func filterBooks(by group: Int) -> [Book] {
        if group == 0 {
            return books
        }
        return books.filter { $0.group == group }
    }
}
