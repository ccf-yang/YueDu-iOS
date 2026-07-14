import SwiftUI

@main
struct YueDuApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // 初始化数据库
                    DatabaseService.shared.initialize()
                }
        }
    }
}

/// 应用全局状态管理
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    static let shared = AppState()
}
