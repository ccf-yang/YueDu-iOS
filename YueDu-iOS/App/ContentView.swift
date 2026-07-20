import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BookshelfView()
                .tabItem { Label("书架", systemImage: "books.vertical.fill") }
                .tag(0)
            NavigationStack { SearchView() }
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(1)
            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gear") }
                .tag(2)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView().environmentObject(AppState())
}
