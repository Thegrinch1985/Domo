import SwiftUI
import Combine

/// Central data store for all Domo data.
/// In a production app, persistence would be handled via SwiftData or CoreData.
@MainActor
final class DomoStore: ObservableObject {
    
    // MARK: - Published Data
    
    @Published var warranties: [WarrantyItem] = WarrantyItem.samples
    @Published var subscriptions: [Subscription] = Subscription.samples
    @Published var vehicles: [Vehicle] = Vehicle.samples
    @Published var insurancePolicies: [InsurancePolicy] = InsurancePolicy.samples
    @Published var maintenanceTasks: [MaintenanceTask] = MaintenanceTask.samples
    
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
        subscriptions.filter { $0.daysUntilRenewal <= 3 }.forEach {
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
    
    // MARK: - CRUD: Warranties
    
    func addWarranty(_ item: WarrantyItem) {
        warranties.append(item)
    }
    
    func deleteWarranty(at offsets: IndexSet) {
        warranties.remove(atOffsets: offsets)
    }
    
    func updateWarranty(_ item: WarrantyItem) {
        guard let index = warranties.firstIndex(where: { $0.id == item.id }) else { return }
        warranties[index] = item
    }
    
    // MARK: - CRUD: Subscriptions
    
    func addSubscription(_ sub: Subscription) {
        subscriptions.append(sub)
    }
    
    func deleteSubscription(at offsets: IndexSet) {
        subscriptions.remove(atOffsets: offsets)
    }
    
    func toggleSubscription(_ sub: Subscription) {
        guard let index = subscriptions.firstIndex(where: { $0.id == sub.id }) else { return }
        subscriptions[index].isActive.toggle()
    }
    
    // MARK: - CRUD: Vehicles
    
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }
    
    func addServiceLog(_ log: ServiceLog, to vehicleID: UUID) {
        guard let index = vehicles.firstIndex(where: { $0.id == vehicleID }) else { return }
        vehicles[index].serviceLogs.append(log)
    }
    
    // MARK: - CRUD: Insurance
    
    func addPolicy(_ policy: InsurancePolicy) {
        insurancePolicies.append(policy)
    }
    
    func deletePolicy(at offsets: IndexSet) {
        insurancePolicies.remove(atOffsets: offsets)
    }
    
    // MARK: - CRUD: Maintenance
    
    func markTaskComplete(_ task: MaintenanceTask) {
        guard let index = maintenanceTasks.firstIndex(where: { $0.id == task.id }) else { return }
        maintenanceTasks[index].lastCompleted = Date()
    }
}
