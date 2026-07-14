import SwiftUI

struct ReaderView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ReaderViewModel
    @State private var showMenu = false
    @State private var showChapterList = false
    
    init(book: Book) {
        _viewModel = StateObject(wrappedValue: ReaderViewModel(book: book))
    }
    
    var body: some View {
        ZStack {
            // 阅读内容
            VStack {
                // 内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 章节标题
                        Text(viewModel.currentChapter?.title ?? "加载中...")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // 章节内容
                        if let content = viewModel.currentContent {
                            Text(content)
                                .font(.system(size: CGFloat(viewModel.fontSize)))
                                .lineSpacing(viewModel.lineSpacing)
                        } else {
                            Text("加载中...")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
                
                // 底部导航
                HStack(spacing: 0) {
                    Button(action: { viewModel.previousChapter() }) {
                        Image(systemName: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                    
                    Button(action: { showChapterList = true }) {
                        Text("目录")
                            .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                    
                    Button(action: { viewModel.nextChapter() }) {
                        Image(systemName: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 44)
                .overlay(Divider(), alignment: .top)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            
            // 菜单
            if showMenu {
                ReaderMenuView(viewModel: viewModel, isPresented: $showMenu)
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            viewModel.loadChapters()
        }
        .sheet(isPresented: $showChapterList) {
            ChapterListView(viewModel: viewModel, isPresented: $showChapterList)
        }
    }
}

// MARK: - ReaderMenuView
struct ReaderMenuView: View {
    @ObservedObject var viewModel: ReaderViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 字体大小调整
            VStack(alignment: .leading, spacing: 10) {
                Text("字体大小")
                    .font(.headline)
                HStack {
                    Button(action: { viewModel.decreaseFontSize() }) {
                        Image(systemName: "minus.circle")
                    }
                    Slider(value: .init(
                        get: { Double(viewModel.fontSize) },
                        set: { viewModel.fontSize = Int($0) }
                    ), in: 12...24, step: 1)
                    Button(action: { viewModel.increaseFontSize() }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            
            // 行距调整
            VStack(alignment: .leading, spacing: 10) {
                Text("行距")
                    .font(.headline)
                Slider(value: $viewModel.lineSpacing, in: 4...12, step: 1)
            }
            
            Divider()
            
            // 关闭按钮
            Button(action: { isPresented = false }) {
                Text("关闭")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - ChapterListView
struct ChapterListView: View {
    @ObservedObject var viewModel: ReaderViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List(viewModel.chapters) { chapter in
                Button(action: {
                    viewModel.goToChapter(chapter)
                    isPresented = false
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.title)
                            .foregroundColor(.primary)
                        if let wordCount = chapter.wordCount {
                            Text(wordCount)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("章节列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { isPresented = false }
                }
            }
        }
    }
}

#Preview {
    let book = Book(id: "test", name: "测试书籍", author: "测试作者")
    ReaderView(book: book)
}
