import SwiftUI
import Combine

/// Global app state shared across all views via @EnvironmentObject
final class AppState: ObservableObject {
    
    @Published var selectedTab: TabItem = .home
    @Published var isOnboarded: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var userName: String = "Howie"
    @Published var userEmail: String = "howie@domo.app"
    @Published var profileInitials: String = "H"
    
    func signOut() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isLoggedIn = false
            selectedTab = .home
        }
    }
    
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
            case .documents:     return "doc.text.fill"
            case .subscriptions: return "arrow.triangle.2.circlepath"
            case .car:           return "car.fill"
            case .vault:         return "shield.checkered"
            }
        }
    }
}
