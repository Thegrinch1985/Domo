import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    @Environment(\.modelContext) private var modelContext
    @Namespace private var tabAnimation
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                mainTabView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                LoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: appState.isLoggedIn)
        .onAppear {
            // Wire model context into DomoStore
            store.modelContext = modelContext
        }
    }
    
    private var mainTabView: some View {
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
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(DomoStore())
        .preferredColorScheme(.dark)
}
