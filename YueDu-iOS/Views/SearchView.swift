import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar
                    .padding()

                if keyword.isEmpty && !vm.isSearching {
                    recentKeywordsView
                } else if vm.isSearching {
                    ProgressView("搜索中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.errorMessage {
                    emptyResultView(message: err)
                } else {
                    resultsList
                }
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }

    // MARK: - 搜索栏

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索书名、作者", text: $keyword)
                    .focused($focused)
                    .submitLabel(.search)
                    .onSubmit { vm.search(keyword: keyword) }
                if !keyword.isEmpty {
                    Button { keyword = ""; vm.searchResults = []; vm.errorMessage = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button("搜索") {
                focused = false
                vm.search(keyword: keyword)
            }
            .disabled(keyword.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - 历史记录

    private var recentKeywordsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !vm.recentKeywords.isEmpty {
                HStack {
                    Text("最近搜索")
                        .font(.headline)
                    Spacer()
                    Button("清空") { vm.clearRecentKeywords() }
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.recentKeywords, id: \.self) { kw in
                            Button(kw) {
                                keyword = kw
                                focused = false
                                vm.search(keyword: kw)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Spacer()
        }
        .padding(.top)
    }

    // MARK: - 搜索结果

    private var resultsList: some View {
        List(vm.searchResults) { result in
            SearchResultRow(result: result) {
                let ok = vm.addToBookshelf(result)
                // 简单 haptic 反馈
                UINotificationFeedbackGenerator().notificationOccurred(ok ? .success : .error)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - 空结果

    private func emptyResultView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 搜索结果行

struct SearchResultRow: View {
    let result: SearchResult
    let onAdd: () -> Void
    @State private var added = false

    var body: some View {
        HStack(spacing: 12) {
            // 封面缩略图
            AsyncImage(url: URL(string: result.book.coverUrl ?? "")) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color.blue.opacity(0.3)
                        Text(result.book.name.prefix(1))
                            .fontWeight(.bold).foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 55, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(result.book.name)
                    .font(.headline).lineLimit(1)
                Text(result.book.author)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                if let intro = result.book.intro {
                    Text(intro)
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text("来源：\(result.sourceName)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()

            Button {
                guard !added else { return }
                added = true
                onAdd()
            } label: {
                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundStyle(added ? .green : .accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
