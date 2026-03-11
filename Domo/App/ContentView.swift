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
        ZStack {
            TabView(selection: $appState.selectedTab) {
                HomeView()
                    .tabItem {
                        Label(AppState.TabItem.home.title,
                              systemImage: AppState.TabItem.home.icon)
                    }
                    .tag(AppState.TabItem.home)
                
                ItemsView()
                    .tabItem {
                        Label(AppState.TabItem.items.title,
                              systemImage: AppState.TabItem.items.icon)
                    }
                    .tag(AppState.TabItem.items)
                
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
                        Label(AppState.TabItem.insurance.title,
                              systemImage: AppState.TabItem.insurance.icon)
                    }
                    .tag(AppState.TabItem.insurance)
            }
            .tint(.blue)
            
            FloatingActionButton()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(DomoStore())
        .preferredColorScheme(.dark)
}
