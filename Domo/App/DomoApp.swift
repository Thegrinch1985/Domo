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
                .task {
                    _ = await NotificationService.shared.requestPermission()
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
            UserAccount.self,
            Asset.self,
            Receipt.self
        ])
    }
}
