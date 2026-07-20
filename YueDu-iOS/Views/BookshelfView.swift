import SwiftUI

struct BookshelfView: View {
    @StateObject private var vm = BookshelfViewModel()
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var showingBook: Book?
    @State private var editMode: EditMode = .inactive

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.displayedBooks.isEmpty {
                    emptyView
                } else {
                    bookGrid
                }
            }
            .navigationTitle("书架")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showSearch = true } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    EditButton()
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAddSheet) {
                AddBookView(vm: vm)
            }
            .onAppear { vm.loadBooks() }
        }
    }

    // MARK: - 书架网格

    private var bookGrid: some View {
        ScrollView {
            // 分组选择器
            if vm.groupNames.count > 1 {
                groupPicker
                    .padding(.horizontal)
            }
            // 排序栏
            sortBar
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filteredBooks) { book in
                    NavigationLink {
                        ReaderView(book: book)
                    } label: {
                        BookCardView(book: book, editMode: editMode) {
                            vm.deleteBook(book)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .refreshable { vm.loadBooks() }
    }

    private var filteredBooks: [Book] {
        searchText.isEmpty ? vm.displayedBooks : vm.searchBooks(keyword: searchText)
    }

    // MARK: - 分组 Picker

    private var groupPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.groupNames, id: \.id) { g in
                    Button {
                        withAnimation { vm.filterGroup = g.id }
                    } label: {
                        Text(g.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(vm.filterGroup == g.id ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(vm.filterGroup == g.id ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - 排序栏

    private var sortBar: some View {
        HStack {
            Text("共\(vm.displayedBooks.count)本")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Menu {
                ForEach(BookshelfViewModel.SortOption.allCases, id: \.self) { opt in
                    Button {
                        vm.sortBy = opt
                        vm.sortBooks()
                    } label: {
                        HStack {
                            Text(opt.rawValue)
                            if vm.sortBy == opt { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                Label(vm.sortBy.rawValue, systemImage: "arrow.up.arrow.down")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 空状态

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("书架空空如也")
                .font(.title2).fontWeight(.medium)
            Text("点击右上角 + 添加书籍\n或前往搜索寻找喜欢的书")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Button("去搜索") { showSearch = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - 书籍卡片

struct BookCardView: View {
    let book: Book
    let editMode: EditMode
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // 封面
                AsyncImage(url: URL(string: book.coverUrl ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        ZStack {
                            LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                            Text(book.name.prefix(2))
                                .font(.title2).fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: 100, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 3)

                // 删除按钮（编辑模式）
                if editMode == .active {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .background(Circle().fill(.white))
                    }
                    .offset(x: 6, y: -6)
                }

                // 阅读进度角标
                if book.durChapterIndex > 0 && book.totalChapterNum > 0 {
                    let pct = Int(Double(book.durChapterIndex) / Double(max(book.totalChapterNum, 1)) * 100)
                    Text("\(pct)%")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(.black.opacity(0.65))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .padding(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .frame(width: 100, height: 140)

            Text(book.name)
                .font(.caption).fontWeight(.medium)
                .lineLimit(2)
                .frame(maxWidth: 100, alignment: .leading)

            Text(book.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - 添加书籍 Sheet

struct AddBookView: View {
    @ObservedObject var vm: BookshelfViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var urlInput = ""
    @State private var isImporting = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            VStack {
                Picker("方式", selection: $tab) {
                    Text("网络搜索").tag(0)
                    Text("本地导入").tag(1)
                    Text("URL直达").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch tab {
                case 0: Text("请使用顶部搜索功能").foregroundStyle(.secondary).padding()
                case 1: LocalImportView(vm: vm)
                case 2: urlImportView
                default: EmptyView()
                }
                Spacer()
            }
            .navigationTitle("添加书籍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var urlImportView: some View {
        VStack(spacing: 16) {
            TextField("输入书籍 URL", text: $urlInput)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding(.horizontal)

            if let err = errorMsg {
                Text(err).foregroundStyle(.red).font(.caption).padding(.horizontal)
            }

            Button("添加") {
                guard StringUtils.shared.isValidURL(urlInput) else {
                    errorMsg = "请输入有效的 URL"; return
                }
                let book = Book(id: urlInput, name: "未知书名", author: "未知作者",
                                origin: "custom", originName: "自定义")
                vm.addBook(book)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(urlInput.isEmpty)
        }
        .padding(.top)
    }
}

// MARK: - 本地导入 View

struct LocalImportView: View {
    @ObservedObject var vm: BookshelfViewModel
    @State private var showFilePicker = false
    @State private var importing = false
    @State private var message: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("支持 TXT / EPUB 格式")
                .font(.subheadline).foregroundStyle(.secondary)
            if let msg = message {
                Text(msg).font(.caption).foregroundStyle(msg.contains("失败") ? .red : .green)
            }
            if importing { ProgressView("导入中...") }
            Button("选择文件") { showFilePicker = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.text, .epub],
            allowsMultipleSelection: false
        ) { result in
            guard let url = (try? result.get())?.first else { return }
            importing = true
            Task {
                do {
                    let book: Book
                    if url.pathExtension.lowercased() == "epub" {
                        book = try await LocalBookService.shared.importEPUB(url: url)
                    } else {
                        book = try await LocalBookService.shared.importTXT(url: url)
                    }
                    vm.addBook(book)
                    await MainActor.run { importing = false; message = "《\(book.name)》导入成功" }
                } catch {
                    await MainActor.run { importing = false; message = "导入失败: \(error.localizedDescription)" }
                }
            }
        }
    }
}
