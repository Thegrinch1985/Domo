import SwiftUI
import SwiftData

@main
struct DomoApp: App {
    
    @StateObject private var appState = AppState()
    @StateObject private var store = DomoStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(store)
                .preferredColorScheme(appState.appearanceMode.colorScheme)
                .onAppear {
                    // modelContext is injected via .modelContainer below;
                    // we wire it into the store in the first view that has access.
                }
        }
        .modelContainer(for: [
            Document.self,
            WarrantyItem.self,
            Subscription.self,
            Vehicle.self,
            ServiceLog.self,
            InsurancePolicy.self,
            MaintenanceTask.self,
            UserAccount.self
        ])
    }
}
