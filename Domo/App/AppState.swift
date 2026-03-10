import SwiftUI
import Combine

/// Global app state shared across all views via @EnvironmentObject
final class AppState: ObservableObject {
    
    @Published var selectedTab: TabItem = .home
    @Published var isOnboarded: Bool = false
    @Published var userName: String = "Howie"
    
    // MARK: - Tab Selection
    enum TabItem: Int, CaseIterable {
        case home
        case documents
        case subscriptions
        case car
        case vault
        
        var title: String {
            switch self {
            case .home:          return "Home"
            case .documents:     return "Docs"
            case .subscriptions: return "Subs"
            case .car:           return "Car"
            case .vault:         return "Vault"
            }
        }
        
        var icon: String {
            switch self {
            case .home:          return "house.fill"
            case .documents:     return "doc.fill"
            case .subscriptions: return "arrow.clockwise.circle.fill"
            case .car:           return "car.fill"
            case .vault:         return "lock.shield.fill"
            }
        }
    }
}
