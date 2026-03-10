import UserNotifications
import Foundation

/// Handles all local notification scheduling for Domo.
/// Call `NotificationService.shared.requestPermission()` on first launch.
final class NotificationService {
    
    static let shared = NotificationService()
    private init() {}
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Warranty Notifications
    
    func scheduleWarrantyReminder(for item: WarrantyItem, daysBefore: Int = 30) {
        let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: item.warrantyExpiry) ?? item.warrantyExpiry
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Warranty Expiring Soon"
        content.body = "\(item.productName) warranty expires in \(daysBefore) days."
        content.sound = .default
        content.categoryIdentifier = "WARRANTY"
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "warranty-\(item.id)", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    // MARK: - Subscription Notifications
    
    func scheduleSubscriptionReminder(for sub: Subscription, daysBefore: Int = 3) {
        let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: sub.renewalDate) ?? sub.renewalDate
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewing"
        content.body = "\(sub.name) renews in \(daysBefore) days — \(sub.price.formatted(.currency(code: "EUR")))"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "subscription-\(sub.id)", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    // MARK: - Maintenance Notifications
    
    func scheduleMaintenanceReminder(for task: MaintenanceTask) {
        guard let dueDate = task.nextDueDate, dueDate > Date() else { return }
        
        // Remind 7 days before
        let triggerDate = Calendar.current.date(byAdding: .day, value: -7, to: dueDate) ?? dueDate
        
        let content = UNMutableNotificationContent()
        content.title = "Maintenance Due"
        content.body = "\(task.title) is due soon."
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "maintenance-\(task.id)", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    // MARK: - Cancel
    
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}
