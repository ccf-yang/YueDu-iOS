import Foundation

class BookshelfViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sortBy: SortOption = .recent
    @Published var filterGroup: Int = 0

    enum SortOption: String, CaseIterable {
        case recent = "最近阅读"
        case name = "书名"
        case author = "作者"
        case updateTime = "更新时间"
    }

    func loadBooks() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let all = DatabaseService.shared.getAllBooks()
            DispatchQueue.main.async {
                self.books = all
                self.sortBooks()
                self.isLoading = false
            }
        }
    }

    @discardableResult
    func addBook(_ book: Book) -> Bool {
        let ok = DatabaseService.shared.saveBook(book)
        if ok { loadBooks() } else { errorMessage = "添加书籍失败" }
        return ok
    }

    @discardableResult
    func deleteBook(_ book: Book) -> Bool {
        let ok = DatabaseService.shared.deleteBook(book.id)
        if ok { books.removeAll { $0.id == book.id } } else { errorMessage = "删除书籍失败" }
        return ok
    }

    @discardableResult
    func updateBook(_ book: Book) -> Bool {
        let ok = DatabaseService.shared.saveBook(book)
        if ok {
            if let idx = books.firstIndex(where: { $0.id == book.id }) { books[idx] = book }
        }
        return ok
    }

    func sortBooks() {
        switch sortBy {
        case .recent:     books.sort { $0.durChapterTime > $1.durChapterTime }
        case .name:       books.sort { $0.name < $1.name }
        case .author:     books.sort { $0.author < $1.author }
        case .updateTime: books.sort { $0.latestChapterTime > $1.latestChapterTime }
        }
    }

    var displayedBooks: [Book] {
        let filtered = filterGroup == 0 ? books : books.filter { $0.group == filterGroup }
        return filtered
    }

    var groupNames: [(id: Int, name: String)] {
        var seen = Set<Int>()
        var result: [(Int, String)] = [(0, "全部")]
        for b in books where !seen.contains(b.group) {
            seen.insert(b.group)
            if b.group != 0 { result.append((b.group, "分组\(b.group)")) }
        }
        return result
    }

    func searchBooks(keyword: String) -> [Book] {
        guard !keyword.isEmpty else { return displayedBooks }
        return displayedBooks.filter {
            $0.name.localizedCaseInsensitiveContains(keyword) ||
            $0.author.localizedCaseInsensitiveContains(keyword)
        }
    }
}
