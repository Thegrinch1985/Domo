import SwiftUI
import Combine

/// Global app state shared across all views via @EnvironmentObject
final class AppState: ObservableObject {
    
    @Published var selectedTab: TabItem = .home
    @Published var isOnboarded: Bool = false
    
    // Auth state
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserAccount?
    
    var userName: String { currentUser?.fullName ?? "" }
    var userEmail: String { currentUser?.email ?? "" }
    var profileInitials: String { currentUser?.initials ?? "?" }
    
    func setUser(_ user: UserAccount) {
        currentUser = user
        isLoggedIn = true
    }
    
    func signOut() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentUser = nil
            isLoggedIn = false
            selectedTab = .home
        }
    }
    
    // MARK: - Notifications
    
    @Published var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled") {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    // MARK: - Currency
    
    static let supportedCurrencies = ["EUR", "USD", "GBP", "CAD", "AUD", "JPY", "CHF", "SEK", "NOK", "DKK"]
    
    @Published var currencyCode: String = UserDefaults.standard.string(forKey: "currencyCode") ?? "EUR" {
        didSet {
            UserDefaults.standard.set(currencyCode, forKey: "currencyCode")
        }
    }
    
    // MARK: - Profile Image
    
    @Published var profileImageData: Data? = UserDefaults.standard.data(forKey: "profileImageData") {
        didSet {
            if let data = profileImageData {
                UserDefaults.standard.set(data, forKey: "profileImageData")
            } else {
                UserDefaults.standard.removeObject(forKey: "profileImageData")
            }
        }
    }
    
    // MARK: - Appearance
    
    enum AppearanceMode: Int, CaseIterable, Identifiable {
        case system = 0
        case light  = 1
        case dark   = 2
        
        var id: Int { rawValue }
        
        var label: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light:  return "sun.max.fill"
            case .dark:   return "moon.fill"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }
    
    @Published var appearanceMode: AppearanceMode = {
        let raw = UserDefaults.standard.integer(forKey: "appearanceMode")
        return AppearanceMode(rawValue: raw) ?? .system
    }() {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    
    // MARK: - Tab Selection
    enum TabItem: Int, CaseIterable {
        case home
        case items
        case subscriptions
        case car
        case insurance
        
        var title: String {
            switch self {
            case .home:          return "Domo"
            case .items:         return "Items"
            case .subscriptions: return "Subs"
            case .car:           return "Car"
            case .insurance:     return "Insurance"
            }
        }
        
        var icon: String {
            switch self {
            case .home:          return "house.fill"
            case .items:         return "cube.box.fill"
            case .subscriptions: return "arrow.triangle.2.circlepath"
            case .car:           return "car.fill"
            case .insurance:     return "shield.checkered"
            }
        }
    }
}
