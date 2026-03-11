import SwiftUI
import SwiftData
import Combine

/// Central data store for all Domo data, now backed by SwiftData.
/// Views can also use @Query directly, but this store provides
/// convenience methods for CRUD operations and computed alerts.
@MainActor
final class DomoStore: ObservableObject {
    
    // The model context is injected from the environment
    var modelContext: ModelContext?
    
    // MARK: - Fetch Helpers
    
    var warranties: [WarrantyItem] {
        fetch(FetchDescriptor<WarrantyItem>(sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]))
    }
    
    var subscriptions: [Subscription] {
        fetch(FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.name)]))
    }
    
    var vehicles: [Vehicle] {
        fetch(FetchDescriptor<Vehicle>(sortBy: [SortDescriptor(\.year, order: .reverse)]))
    }
    
    var insurancePolicies: [InsurancePolicy] {
        fetch(FetchDescriptor<InsurancePolicy>(sortBy: [SortDescriptor(\.expiryDate)]))
    }
    
    var maintenanceTasks: [MaintenanceTask] {
        fetch(FetchDescriptor<MaintenanceTask>(sortBy: [SortDescriptor(\.title)]))
    }
    
    var assets: [Asset] {
        fetch(FetchDescriptor<Asset>(sortBy: [SortDescriptor(\.name)]))
    }
    
    var receipts: [Receipt] {
        fetch(FetchDescriptor<Receipt>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }
    
    var documents: [Document] {
        fetch(FetchDescriptor<Document>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }
    
    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        (try? modelContext?.fetch(descriptor)) ?? []
    }
    
    // MARK: - Document Link Helpers
    
    func documents(forAssetID assetID: UUID) -> [Document] {
        var descriptor = FetchDescriptor<Document>(
            predicate: #Predicate<Document> { $0.linkedAssetID == assetID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        return (try? modelContext?.fetch(descriptor)) ?? []
    }
    
    func documents(forVehicleID vehicleID: UUID) -> [Document] {
        var descriptor = FetchDescriptor<Document>(
            predicate: #Predicate<Document> { $0.linkedVehicleID == vehicleID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        return (try? modelContext?.fetch(descriptor)) ?? []
    }
    
    func documents(forPolicyID policyID: UUID) -> [Document] {
        var descriptor = FetchDescriptor<Document>(
            predicate: #Predicate<Document> { $0.linkedPolicyID == policyID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        return (try? modelContext?.fetch(descriptor)) ?? []
    }
    
    // MARK: - Computed Properties
    
    var totalMonthlySpend: Double {
        subscriptions.filter(\.isActive).reduce(0) { $0 + $1.monthlyEquivalent }
    }
    
    var totalYearlySpend: Double { totalMonthlySpend * 12 }
    
    var urgentAlerts: [String] {
        var alerts: [String] = []
        
        warranties.filter(\.isExpiringSoon).forEach {
            alerts.append("\($0.productName) warranty expires in \($0.daysRemaining) days")
        }
        subscriptions.filter { $0.daysUntilRenewal <= 3 && $0.isActive }.forEach {
            alerts.append("\($0.name) renews in \($0.daysUntilRenewal) days")
        }
        maintenanceTasks.filter { $0.isOverdue || $0.isDueSoon }.forEach {
            alerts.append("\($0.title) is due")
        }
        vehicles.filter(\.isServiceDue).forEach {
            alerts.append("\($0.displayName) service due soon")
        }
        
        return alerts
    }
    
    // MARK: - Refresh trigger (call after mutations to refresh views)
    
    func refresh() {
        objectWillChange.send()
    }
    
    // MARK: - CRUD: Warranties
    
    func addWarranty(_ item: WarrantyItem) {
        modelContext?.insert(item)
        save()
        NotificationService.shared.scheduleWarrantyReminder(for: item)
    }
    
    func deleteWarranty(_ item: WarrantyItem) {
        NotificationService.shared.cancelNotification(identifier: "warranty-\(item.id)")
        modelContext?.delete(item)
        save()
    }
    
    func deleteWarranties(at offsets: IndexSet) {
        let items = warranties
        for index in offsets {
            modelContext?.delete(items[index])
        }
        save()
    }
    
    // MARK: - CRUD: Subscriptions
    
    func addSubscription(_ sub: Subscription) {
        modelContext?.insert(sub)
        save()
        NotificationService.shared.scheduleSubscriptionReminder(for: sub)
    }
    
    func deleteSubscription(_ sub: Subscription) {
        NotificationService.shared.cancelNotification(identifier: "subscription-\(sub.id)")
        modelContext?.delete(sub)
        save()
    }
    
    func deleteSubscriptions(at offsets: IndexSet) {
        let items = subscriptions
        for index in offsets {
            modelContext?.delete(items[index])
        }
        save()
    }
    
    func toggleSubscription(_ sub: Subscription) {
        sub.isActive.toggle()
        save()
        if sub.isActive {
            NotificationService.shared.scheduleSubscriptionReminder(for: sub)
        } else {
            NotificationService.shared.cancelNotification(identifier: "subscription-\(sub.id)")
        }
    }
    
    // MARK: - CRUD: Vehicles
    
    func addVehicle(_ vehicle: Vehicle) {
        modelContext?.insert(vehicle)
        save()
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        modelContext?.delete(vehicle)
        save()
    }
    
    func addServiceLog(_ log: ServiceLog, to vehicle: Vehicle) {
        log.vehicle = vehicle
        vehicle.serviceLogs.append(log)
        save()
    }
    
    // MARK: - CRUD: Insurance
    
    func addPolicy(_ policy: InsurancePolicy) {
        modelContext?.insert(policy)
        save()
        NotificationService.shared.scheduleInsuranceReminder(for: policy)
    }
    
    func deletePolicy(_ policy: InsurancePolicy) {
        NotificationService.shared.cancelNotification(identifier: "insurance-\(policy.id)")
        modelContext?.delete(policy)
        save()
    }
    
    func deletePolicies(at offsets: IndexSet) {
        let items = insurancePolicies
        for index in offsets {
            modelContext?.delete(items[index])
        }
        save()
    }
    
    // MARK: - CRUD: Maintenance
    
    func addTask(_ task: MaintenanceTask) {
        modelContext?.insert(task)
        save()
        NotificationService.shared.scheduleMaintenanceReminder(for: task)
    }
    
    func deleteTask(_ task: MaintenanceTask) {
        NotificationService.shared.cancelNotification(identifier: "maintenance-\(task.id)")
        modelContext?.delete(task)
        save()
    }
    
    func markTaskComplete(_ task: MaintenanceTask) {
        task.lastCompleted = Date()
        save()
        // Reschedule for the next due date
        NotificationService.shared.scheduleMaintenanceReminder(for: task)
    }
    
    // MARK: - CRUD: Assets
    
    func addAsset(_ asset: Asset) {
        modelContext?.insert(asset)
        save()
    }
    
    func deleteAsset(_ asset: Asset) {
        modelContext?.delete(asset)
        save()
    }
    
    func deleteAssets(at offsets: IndexSet) {
        let items = assets
        for index in offsets {
            modelContext?.delete(items[index])
        }
        save()
    }
    
    // MARK: - CRUD: Receipts
    
    func addReceipt(_ receipt: Receipt) {
        modelContext?.insert(receipt)
        save()
    }
    
    func deleteReceipt(_ receipt: Receipt) {
        modelContext?.delete(receipt)
        save()
    }
    
    func deleteReceipts(at offsets: IndexSet) {
        let items = receipts
        for index in offsets {
            modelContext?.delete(items[index])
        }
        save()
    }
    
    // MARK: - Save
    
    private func save() {
        try? modelContext?.save()
        refresh()
    }
}
