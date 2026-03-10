import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            
            HomeView()
                .tabItem {
                    Label(AppState.TabItem.home.title,
                          systemImage: AppState.TabItem.home.icon)
                }
                .tag(AppState.TabItem.home)
            
            DocumentsView()
                .tabItem {
                    Label(AppState.TabItem.documents.title,
                          systemImage: AppState.TabItem.documents.icon)
                }
                .tag(AppState.TabItem.documents)
            
            SubscriptionsView()
                .tabItem {
                    Label(AppState.TabItem.subscriptions.title,
                          systemImage: AppState.TabItem.subscriptions.icon)
                }
                .tag(AppState.TabItem.subscriptions)
            
            CarView()
                .tabItem {
                    Label(AppState.TabItem.car.title,
                          systemImage: AppState.TabItem.car.icon)
                }
                .tag(AppState.TabItem.car)
            
            InsuranceVaultView()
                .tabItem {
                    Label(AppState.TabItem.vault.title,
                          systemImage: AppState.TabItem.vault.icon)
                }
                .tag(AppState.TabItem.vault)
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
