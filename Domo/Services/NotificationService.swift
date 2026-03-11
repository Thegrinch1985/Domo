import UserNotifications
import Foundation

/// Handles all local notification scheduling for Domo.
/// Call `NotificationService.shared.requestPermission()` on first launch.
final class NotificationService: @unchecked Sendable {
    
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
    
    /// Schedules a notification for warranty expiry.
    /// Uses the item's `reminderDate` if set, otherwise defaults to 30 days before expiry.
    func scheduleWarrantyReminder(for item: WarrantyItem) {
        let triggerDate: Date
        if let reminder = item.reminderDate {
            triggerDate = reminder
        } else {
            triggerDate = Calendar.current.date(byAdding: .day, value: -30, to: item.warrantyExpiry) ?? item.warrantyExpiry
        }
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Warranty Expiring Soon"
        content.body = "\(item.productName) warranty expires on \(item.warrantyExpiry.formatted(date: .abbreviated, time: .omitted))."
        content.sound = .default
        content.categoryIdentifier = "WARRANTY"
        
        schedule(identifier: "warranty-\(item.id)", date: triggerDate, content: content)
    }
    
    // MARK: - Subscription Notifications
    
    /// Schedules a notification for subscription renewal.
    /// Uses the sub's `reminderDate` if set, otherwise defaults to 3 days before renewal.
    func scheduleSubscriptionReminder(for sub: Subscription) {
        let triggerDate: Date
        if let reminder = sub.reminderDate {
            triggerDate = reminder
        } else {
            triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: sub.renewalDate) ?? sub.renewalDate
        }
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewing"
        content.body = "\(sub.name) renews on \(sub.renewalDate.formatted(date: .abbreviated, time: .omitted)) — \(sub.price.formatted(.currency(code: "EUR")))"
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION"
        
        schedule(identifier: "subscription-\(sub.id)", date: triggerDate, content: content)
    }
    
    // MARK: - Maintenance Notifications
    
    /// Schedules a notification for a maintenance task.
    /// Uses the task's `reminderDate` if set, otherwise defaults to 7 days before due.
    func scheduleMaintenanceReminder(for task: MaintenanceTask) {
        let triggerDate: Date
        if let reminder = task.reminderDate {
            triggerDate = reminder
        } else {
            guard let dueDate = task.nextDueDate else { return }
            triggerDate = Calendar.current.date(byAdding: .day, value: -7, to: dueDate) ?? dueDate
        }
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Maintenance Due"
        content.body = "\(task.title) is coming up. Time to schedule it."
        content.sound = .default
        content.categoryIdentifier = "MAINTENANCE"
        
        schedule(identifier: "maintenance-\(task.id)", date: triggerDate, content: content)
    }
    
    // MARK: - Insurance Notifications
    
    /// Schedules a notification for insurance policy renewal.
    /// Uses the policy's `reminderDate` if set, otherwise defaults to 30 days before expiry.
    func scheduleInsuranceReminder(for policy: InsurancePolicy) {
        let triggerDate: Date
        if let reminder = policy.reminderDate {
            triggerDate = reminder
        } else {
            triggerDate = Calendar.current.date(byAdding: .day, value: -30, to: policy.expiryDate) ?? policy.expiryDate
        }
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Insurance Renewal"
        content.body = "\(policy.provider) \(policy.type.rawValue) expires on \(policy.expiryDate.formatted(date: .abbreviated, time: .omitted))."
        content.sound = .default
        content.categoryIdentifier = "INSURANCE"
        
        schedule(identifier: "insurance-\(policy.id)", date: triggerDate, content: content)
    }
    
    // MARK: - Cancel
    
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Private
    
    private func schedule(identifier: String, date: Date, content: UNMutableNotificationContent) {
        // Remove any existing notification with this identifier first
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        // Default to 9 AM if the time component isn't meaningful
        if components.hour == 0 && components.minute == 0 {
            components.hour = 9
            components.minute = 0
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule notification \(identifier): \(error.localizedDescription)")
            }
        }
    }
}
