import SwiftUI

struct BookshelfView: View {
    @StateObject private var viewModel = BookshelfViewModel()
    @State private var showAddBookSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.books.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("还没有添加书籍")
                            .font(.headline)
                        Text("点击下方按钮添加书籍开始阅读")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 100), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(viewModel.books) { book in
                                NavigationLink(destination: ReaderView(book: book)) {
                                    BookCoverView(book: book)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("书架")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddBookSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBookSheet) {
                AddBookView(isPresented: $showAddBookSheet)
            }
        }
        .onAppear {
            viewModel.loadBooks()
        }
    }
}

// MARK: - BookCoverView
struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                
                if let coverUrl = book.displayCover, !coverUrl.isEmpty {
                    AsyncImage(url: URL(string: coverUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "book.fill")
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "book.fill")
                        .foregroundColor(.gray)
                }
            }
            .aspectRatio(2/3, contentMode: .fit)
            
            // 书名
            Text(book.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            // 作者
            Text(book.author)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            // 进度
            if book.totalChapterNum > 0 {
                ProgressView(value: Double(book.durChapterIndex) / Double(book.totalChapterNum))
                    .scaleEffect(y: 0.8, anchor: .center)
            }
        }
    }
}

// MARK: - AddBookView
struct AddBookView: View {
    @Binding var isPresented: Bool
    @State private var bookName: String = ""
    @State private var authorName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("书籍信息")) {
                    TextField("书名", text: $bookName)
                    TextField("作者", text: $authorName)
                }
            }
            .navigationTitle("添加书籍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        // TODO: 实现添加书籍逻辑
                        isPresented = false
                    }
                    .disabled(bookName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    BookshelfView()
}
