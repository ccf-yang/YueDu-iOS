import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索书籍", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                // 搜索结果
                if isSearching {
                    VStack {
                        ProgressView()
                        Text("搜索中...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("未找到相关书籍")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if !searchResults.isEmpty {
                    List(searchResults) { book in
                        NavigationLink(destination: ReaderView(book: book)) {
                            SearchResultRow(book: book)
                        }
                    }
                    .listStyle(.plain)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("输入关键词搜索书籍")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationTitle("搜索")
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        
        // TODO: 实现搜索逻辑
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSearching = false
            searchResults = []
        }
    }
}

// MARK: - SearchResultRow
struct SearchResultRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            // 封面
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                if let coverUrl = book.displayCover, !coverUrl.isEmpty {
                    AsyncImage(url: URL(string: coverUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "book.fill")
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Image(systemName: "book.fill")
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 60, height: 90)
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let intro = book.displayIntro, !intro.isEmpty {
                    Text(intro)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if let source = book.originName as String? {
                    Text(source)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .frame(height: 120)
    }
}

#Preview {
    SearchView()
}
