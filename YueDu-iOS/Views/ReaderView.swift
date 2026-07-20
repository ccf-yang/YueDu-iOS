import SwiftUI

struct ReaderView: View {
    @StateObject private var vm: ReaderViewModel
    @State private var showMenu = false
    @State private var showTOC = false
    @State private var showSettings = false
    @State private var showBookmarks = false
    @Environment(\.dismiss) private var dismiss

    init(book: Book) {
        _vm = StateObject(wrappedValue: ReaderViewModel(book: book))
    }

    var body: some View {
        let theme = ReaderViewModel.bgColors[vm.bgColorIndex]
        let bgColor  = Color(hex: theme.bg)  ?? .white
        let fgColor  = Color(hex: theme.fg)  ?? .black

        ZStack {
            bgColor.ignoresSafeArea()

            if vm.isLoading {
                ProgressView("加载中...").tint(fgColor)
            } else if let err = vm.errorMessage {
                errorView(msg: err, fg: fgColor)
            } else {
                VStack(spacing: 0) {
                    // 顶部状态栏
                    readerHeader(fg: fgColor, bg: bgColor)
                    // 正文
                    contentArea(fg: fgColor, bg: bgColor)
                    // 底部进度栏
                    readerFooter(fg: fgColor)
                }
            }

            // 中央点击响应区（展开/收起菜单）
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showMenu.toggle() } }

            // 菜单覆盖层
            if showMenu {
                readerMenu(bg: bgColor, fg: fgColor)
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: showMenu ? false : true)
        .sheet(isPresented: $showTOC) {
            TocView(vm: vm)
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsSheet(vm: vm)
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView(vm: vm)
        }
        .onAppear {
            vm.loadChapters()
            vm.loadBookmarks()
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    // 左滑下一章，右滑上一章
                    if value.translation.width < -50 { vm.nextChapter() }
                    if value.translation.width > 50  { vm.previousChapter() }
                }
        )
    }

    // MARK: - 顶部栏

    private func readerHeader(fg: Color, bg: Color) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(fg.opacity(0.7))
            }
            .padding(.leading, 16)

            Spacer()

            Text(vm.currentChapter?.title ?? vm.book.name)
                .font(.caption).foregroundStyle(fg.opacity(0.6))
                .lineLimit(1)

            Spacer()

            Button {
                vm.addBookmark(pos: 0)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                Image(systemName: "bookmark")
                    .foregroundStyle(fg.opacity(0.7))
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(bg)
    }

    // MARK: - 正文区

    private func contentArea(fg: Color, bg: Color) -> some View {
        ScrollView {
            if let content = vm.currentContent {
                Text(content)
                    .font(.system(size: CGFloat(vm.fontSize)))
                    .foregroundStyle(fg)
                    .lineSpacing(vm.lineSpacing)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(bg)
    }

    // MARK: - 底部进度栏

    private func readerFooter(fg: Color) -> some View {
        HStack {
            Text(vm.currentChapter.map { "\($0.index + 1)/\(vm.chapters.count)" } ?? "")
                .font(.caption2).foregroundStyle(fg.opacity(0.5))
                .padding(.leading, 16)
            Spacer()
            ProgressView(value: vm.progress)
                .tint(fg.opacity(0.4))
                .frame(width: 100)
            Spacer()
            Text(DateUtils.shared.format(Date(), format: "HH:mm"))
                .font(.caption2).foregroundStyle(fg.opacity(0.5))
                .padding(.trailing, 16)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 阅读菜单

    private func readerMenu(bg: Color, fg: Color) -> some View {
        VStack {
            // 顶部菜单
            HStack(spacing: 24) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
                Text(vm.book.name).font(.headline).lineLimit(1)
                Spacer()
                Button { showBookmarks = true } label: {
                    Image(systemName: "bookmark.fill")
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Spacer()

            // 底部菜单
            VStack(spacing: 12) {
                // 章节翻页
                HStack(spacing: 32) {
                    Button("上一章") { vm.previousChapter() }
                        .disabled(vm.currentChapterIndex == 0)
                    Spacer()
                    Button("下一章") { vm.nextChapter() }
                        .disabled(vm.currentChapterIndex >= vm.chapters.count - 1)
                }
                .padding(.horizontal, 24)

                Divider()

                // 功能按钮
                HStack(spacing: 0) {
                    readerMenuBtn(icon: "list.bullet", label: "目录") { showTOC = true }
                    readerMenuBtn(icon: "textformat.size", label: "设置") { showSettings = true }
                    readerMenuBtn(icon: "sun.max", label: "亮度") {}
                    readerMenuBtn(icon: "ellipsis", label: "更多") {}
                }
            }
            .padding(.bottom, 32)
            .background(.ultraThinMaterial)
        }
        .foregroundStyle(fg)
        .onTapGesture { withAnimation { showMenu = false } }
    }

    private func readerMenuBtn(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - 错误视图

    private func errorView(msg: String, fg: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48)).foregroundStyle(.orange)
            Text(msg).multilineTextAlignment(.center).foregroundStyle(fg)
            Button("重试") { vm.loadChapters() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - 目录 View

struct TocView: View {
    @ObservedObject var vm: ReaderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(vm.chapters) { chapter in
                Button {
                    vm.goToChapter(chapter)
                    dismiss()
                } label: {
                    HStack {
                        Text(chapter.title)
                            .foregroundStyle(chapter.index == vm.currentChapterIndex
                                ? Color.accentColor
                                : Color.primary)
                        Spacer()
                        if chapter.index == vm.currentChapterIndex {
                            Image(systemName: "bookmark.fill")
                                .font(.caption).foregroundStyle(Color.accentColor)
                        }
                        if chapter.isVip {
                            Text("VIP").font(.caption2).foregroundStyle(.orange)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 书签列表

struct BookmarksView: View {
    @ObservedObject var vm: ReaderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if vm.bookmarks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash").font(.system(size: 48)).foregroundStyle(.secondary)
                        Text("暂无书签").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.bookmarks) { bm in
                            Button {
                                if let idx = vm.chapters.firstIndex(where: { $0.index == bm.chapterIndex }) {
                                    vm.jumpToChapter(index: idx)
                                }
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bm.chapterTitle).font(.headline)
                                    Text(bm.content).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    Text(DateUtils.shared.format(bm.createTime))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { i in vm.deleteBookmark(vm.bookmarks[i]) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("书签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 阅读设置面板

struct ReaderSettingsSheet: View {
    @ObservedObject var vm: ReaderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("字体大小") {
                    HStack {
                        Button { vm.decreaseFontSize() } label: {
                            Image(systemName: "textformat.size.smaller").font(.title3)
                        }
                        Spacer()
                        Text("\(vm.fontSize)pt").font(.system(size: CGFloat(vm.fontSize)))
                        Spacer()
                        Button { vm.increaseFontSize() } label: {
                            Image(systemName: "textformat.size.larger").font(.title3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("背景颜色") {
                    HStack(spacing: 12) {
                        ForEach(ReaderViewModel.bgColors.indices, id: \.self) { i in
                            let c = ReaderViewModel.bgColors[i]
                            Circle()
                                .fill(Color(hex: c.bg) ?? .white)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(
                                        vm.bgColorIndex == i ? Color.accentColor : Color.gray.opacity(0.3),
                                        lineWidth: vm.bgColorIndex == i ? 3 : 1
                                    )
                                )
                                .onTapGesture { vm.bgColorIndex = i }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("行间距") {
                    Slider(value: $vm.lineSpacing, in: 4...20, step: 2) {
                        Text("行间距")
                    } minimumValueLabel: {
                        Text("紧").font(.caption)
                    } maximumValueLabel: {
                        Text("宽").font(.caption)
                    }
                }
            }
            .navigationTitle("阅读设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Color(hex:) 扩展

extension Color {
    init?(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >>  8) & 0xFF) / 255,
            blue:  Double( val        & 0xFF) / 255
        )
    }
}
