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
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Document.self)
    }
}
