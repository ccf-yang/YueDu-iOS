import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @State private var showImportSheet = false
    @State private var showURLImport = false
    @State private var showExportShareSheet = false
    @State private var showDataImport = false
    @State private var importURLText = ""
    @State private var exportURL: URL?
    @State private var cacheSize = ""
    @State private var showAddSource = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 书源管理
                Section("书源管理") {
                    NavigationLink("管理书源 (\(vm.bookSources.count))") {
                        BookSourceListView(vm: vm)
                    }
                    Button("导入书源（JSON文件）") { showImportSheet = true }
                    Button("从URL导入书源") { showURLImport = true }
                    Button("导出书源") {
                        Task {
                            if let json = BookSourceService.shared.exportBookSources() {
                                let url = FileManager.default.temporaryDirectory
                                    .appendingPathComponent("book_sources.json")
                                try? json.write(to: url, atomically: true, encoding: .utf8)
                                exportURL = url
                                showExportShareSheet = true
                            }
                        }
                    }
                }

                // MARK: - 数据管理
                Section("数据管理") {
                    Button("备份全部数据") {
                        vm.exportData { url in
                            exportURL = url
                            if url != nil { showExportShareSheet = true }
                        }
                    }
                    Button("恢复备份") { showDataImport = true }
                }

                // MARK: - 存储
                Section("存储") {
                    HStack {
                        Text("缓存大小")
                        Spacer()
                        Text(cacheSize.isEmpty ? vm.getCacheSize() : cacheSize)
                            .foregroundStyle(.secondary)
                    }
                    Button("清除缓存", role: .destructive) {
                        vm.clearCache { freed in cacheSize = "已释放 \(freed)" }
                    }
                }

                // MARK: - 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("\(vm.appVersion) (\(vm.buildNumber))")
                            .foregroundStyle(Color.secondary)
                    }
                    HStack {
                        Text("项目主页")
                        Spacer()
                        Text("github.com/gedoor/legado")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("提示", isPresented: $vm.showAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(vm.alertMessage ?? "")
            }
            .sheet(isPresented: $showURLImport) {
                urlImportSheet
            }
            .sheet(isPresented: $showExportShareSheet) {
                if let url = exportURL { ShareSheet(activityItems: [url]) }
            }
            .fileImporter(isPresented: $showImportSheet,
                          allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                if let url = (try? result.get())?.first,
                   let json = try? String(contentsOf: url) {
                    vm.importBookSourcesFromJSON(json)
                }
            }
            .fileImporter(isPresented: $showDataImport,
                          allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                if let url = (try? result.get())?.first {
                    vm.importData(from: url)
                }
            }
            .onAppear { vm.loadBookSources() }
        }
    }

    private var urlImportSheet: some View {
        NavigationStack {
            Form {
                Section("从 URL 导入书源") {
                    TextField("输入书源JSON地址", text: $importURLText)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("URL导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showURLImport = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        vm.importBookSourcesFromURL(importURLText)
                        showURLImport = false
                    }
                    .disabled(importURLText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 书源列表页

struct BookSourceListView: View {
    @ObservedObject var vm: SettingsViewModel
    @State private var showAdd = false
    @State private var editingSource: BookSource?
    @State private var searchText = ""

    var filtered: [BookSource] {
        searchText.isEmpty ? vm.bookSources :
        vm.bookSources.filter {
            $0.bookSourceName.localizedCaseInsensitiveContains(searchText) ||
            ($0.bookSourceGroup ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { source in
                BookSourceRow(source: source,
                    onToggle: { vm.toggleBookSource(source, enabled: $0) },
                    onEdit: { editingSource = source }
                )
            }
            .onDelete { idx in
                idx.forEach { i in vm.deleteBookSource(filtered[i]) }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "搜索书源")
        .navigationTitle("书源管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            BookSourceEditorView(existing: nil) { vm.addBookSource($0) }
        }
        .sheet(item: $editingSource) { source in
            BookSourceEditorView(existing: source) { vm.addBookSource($0) }
        }
    }
}

// MARK: - 书源行

struct BookSourceRow: View {
    let source: BookSource
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    @State private var enabled: Bool

    init(source: BookSource, onToggle: @escaping (Bool) -> Void, onEdit: @escaping () -> Void) {
        self.source = source
        self.onToggle = onToggle
        self.onEdit = onEdit
        _enabled = State(initialValue: source.enabled)
    }

    var body: some View {
        HStack {
            Toggle("", isOn: $enabled)
                .labelsHidden()
                .onChange(of: enabled) { onToggle($0) }
            VStack(alignment: .leading, spacing: 2) {
                Text(source.bookSourceName).font(.headline)
                HStack(spacing: 6) {
                    if let g = source.bookSourceGroup {
                        Text(g).font(.caption).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15)).clipShape(Capsule())
                    }
                    Text(source.bookSourceUrl).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 书源编辑器

struct BookSourceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let existing: BookSource?
    let onSave: (BookSource) -> Void

    @State private var name = ""
    @State private var url = ""
    @State private var group = ""
    @State private var header = ""
    @State private var ruleSearch = ""
    @State private var ruleBookInfo = ""
    @State private var ruleToc = ""
    @State private var ruleContent = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("书源名称 *", text: $name)
                    TextField("书源URL *", text: $url).keyboardType(.URL).autocapitalization(.none)
                    TextField("分组（可选）", text: $group)
                    TextField("请求头 JSON（可选）", text: $header)
                }
                Section("搜索规则 (JSON)") {
                    TextEditor(text: $ruleSearch).frame(minHeight: 80).font(.caption)
                }
                Section("书籍信息规则 (JSON)") {
                    TextEditor(text: $ruleBookInfo).frame(minHeight: 60).font(.caption)
                }
                Section("目录规则 (JSON)") {
                    TextEditor(text: $ruleToc).frame(minHeight: 60).font(.caption)
                }
                Section("正文规则 (JSON)") {
                    TextEditor(text: $ruleContent).frame(minHeight: 60).font(.caption)
                }
            }
            .navigationTitle(existing == nil ? "添加书源" : "编辑书源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let source = BookSource(
                            bookSourceUrl: url.trimmingCharacters(in: .whitespaces),
                            bookSourceName: name.trimmingCharacters(in: .whitespaces),
                            bookSourceGroup: group.isEmpty ? nil : group,
                            header: header.isEmpty ? nil : header,
                            ruleSearch: ruleSearch.isEmpty ? nil : ruleSearch,
                            ruleBookInfo: ruleBookInfo.isEmpty ? nil : ruleBookInfo,
                            ruleToc: ruleToc.isEmpty ? nil : ruleToc,
                            ruleContent: ruleContent.isEmpty ? nil : ruleContent
                        )
                        onSave(source)
                        dismiss()
                    }
                    .disabled(name.isEmpty || url.isEmpty)
                }
            }
            .onAppear {
                guard let s = existing else { return }
                name = s.bookSourceName; url = s.bookSourceUrl
                group = s.bookSourceGroup ?? ""; header = s.header ?? ""
                ruleSearch = s.ruleSearch ?? ""; ruleBookInfo = s.ruleBookInfo ?? ""
                ruleToc = s.ruleToc ?? ""; ruleContent = s.ruleContent ?? ""
            }
        }
    }
}

// MARK: - 系统分享 Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
