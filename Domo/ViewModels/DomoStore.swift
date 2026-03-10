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
    
    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        (try? modelContext?.fetch(descriptor)) ?? []
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
    }
    
    func deleteWarranty(_ item: WarrantyItem) {
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
    }
    
    func deleteSubscription(_ sub: Subscription) {
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
    }
    
    func deletePolicy(_ policy: InsurancePolicy) {
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
    }
    
    func deleteTask(_ task: MaintenanceTask) {
        modelContext?.delete(task)
        save()
    }
    
    func markTaskComplete(_ task: MaintenanceTask) {
        task.lastCompleted = Date()
        save()
    }
    
    // MARK: - Save
    
    private func save() {
        try? modelContext?.save()
        refresh()
    }
}
