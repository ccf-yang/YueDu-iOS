import SwiftUI

struct SettingsView: View {
    @State private var appVersion = "1.0.0"
    @State private var buildNumber = "1"
    
    var body: some View {
        NavigationStack {
            Form {
                // 关于应用
                Section(header: Text("关于应用")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("构建号")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.gray)
                    }
                }
                
                // 阅读设置
                Section(header: Text("阅读设置")) {
                    NavigationLink(destination: ReadingPreferencesView()) {
                        Label("阅读偏好", systemImage: "book.fill")
                    }
                }
                
                // 数据管理
                Section(header: Text("数据管理")) {
                    NavigationLink(destination: BookSourceManagementView()) {
                        Label("书源管理", systemImage: "link")
                    }
                    Button(action: { exportData() }) {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                            .foregroundColor(.primary)
                    }
                    Button(action: { importData() }) {
                        Label("导入数据", systemImage: "square.and.arrow.down")
                            .foregroundColor(.primary)
                    }
                }
                
                // 关于
                Section(header: Text("关于")) {
                    Link(destination: URL(string: "https://github.com/ccf-yang/YueDu-iOS")!) {
                        Label("GitHub", systemImage: "link")
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
    
    private func exportData() {
        // TODO: 实现导出数据逻辑
    }
    
    private func importData() {
        // TODO: 实现导入数据逻辑
    }
}

// MARK: - ReadingPreferencesView
struct ReadingPreferencesView: View {
    @State private var fontSize: Int = 16
    @State private var lineSpacing: CGFloat = 6
    @State private var brightness: CGFloat = 1.0
    
    var body: some View {
        Form {
            Section(header: Text("字体")) {
                HStack {
                    Text("字体大小")
                    Spacer()
                    Stepper("\(fontSize)", value: $fontSize, in: 12...24)
                }
            }
            
            Section(header: Text("排版")) {
                HStack {
                    Text("行距")
                    Spacer()
                    Stepper(String(format: "%.1f", lineSpacing), value: $lineSpacing, in: 4...12, step: 0.5)
                }
            }
            
            Section(header: Text("显示")) {
                HStack {
                    Text("亮度")
                    Spacer()
                    Slider(value: $brightness, in: 0.5...1.5)
                }
            }
        }
        .navigationTitle("阅读偏好")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - BookSourceManagementView
struct BookSourceManagementView: View {
    @State private var bookSources: [BookSource] = []
    @State private var showAddSource = false
    
    var body: some View {
        ZStack {
            if bookSources.isEmpty {
                VStack {
                    Image(systemName: "link")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暂无书源")
                        .foregroundColor(.gray)
                }
            } else {
                List(bookSources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.bookSourceName)
                            .font(.headline)
                        Text(source.bookSourceUrl)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("书源管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSource = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSource) {
            AddBookSourceView(isPresented: $showAddSource)
        }
    }
}

// MARK: - AddBookSourceView
struct AddBookSourceView: View {
    @Binding var isPresented: Bool
    @State private var sourceUrl: String = ""
    @State private var sourceName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("书源 URL", text: $sourceUrl)
                TextField("书源名称", text: $sourceName)
            }
            .navigationTitle("添加书源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        // TODO: 实现添加书源逻辑
                        isPresented = false
                    }
                    .disabled(sourceUrl.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
