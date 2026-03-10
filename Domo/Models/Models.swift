import Foundation
import SwiftUI

// MARK: - Warranty

struct WarrantyItem: Identifiable, Codable {
    var id: UUID = UUID()
    var productName: String
    var storeName: String
    var purchaseDate: Date
    var warrantyYears: Int
    var price: Double
    var category: ProductCategory
    var documentURL: URL?
    
    var warrantyExpiry: Date {
        Calendar.current.date(byAdding: .year, value: warrantyYears, to: purchaseDate) ?? purchaseDate
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: warrantyExpiry).day ?? 0
    }
    
    var isExpiringSoon: Bool { daysRemaining <= 30 }
    var isExpired: Bool { daysRemaining < 0 }
    
    var statusColor: Color {
        if isExpired      { return .red }
        if isExpiringSoon { return .orange }
        return .green
    }
    
    enum ProductCategory: String, CaseIterable, Codable {
        case electronics = "Electronics"
        case appliances  = "Appliances"
        case furniture   = "Furniture"
        case automotive  = "Automotive"
        case other       = "Other"
        
        var icon: String {
            switch self {
            case .electronics: return "laptopcomputer"
            case .appliances:  return "washer"
            case .furniture:   return "sofa"
            case .automotive:  return "car"
            case .other:       return "archivebox"
            }
        }
    }
}

// MARK: - Subscription

struct Subscription: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var price: Double
    var billingCycle: BillingCycle
    var renewalDate: Date
    var category: SubscriptionCategory
    var iconName: String   // SF Symbol or custom asset name
    var colorHex: String   // Hex string e.g. "#1DB954"
    var isActive: Bool = true
    
    var monthlyEquivalent: Double {
        switch billingCycle {
        case .monthly:  return price
        case .yearly:   return price / 12
        case .weekly:   return price * 4.33
        }
    }
    
    var daysUntilRenewal: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: renewalDate).day ?? 0
    }
    
    enum BillingCycle: String, CaseIterable, Codable {
        case monthly = "Monthly"
        case yearly  = "Yearly"
        case weekly  = "Weekly"
    }
    
    enum SubscriptionCategory: String, CaseIterable, Codable {
        case entertainment = "Entertainment"
        case productivity  = "Productivity"
        case health        = "Health & Fitness"
        case utilities     = "Utilities"
        case shopping      = "Shopping"
        case other         = "Other"
    }
}

// MARK: - Car

struct Vehicle: Identifiable, Codable {
    var id: UUID = UUID()
    var make: String
    var model: String
    var year: Int
    var plate: String
    var currentMileage: Int
    var nextServiceMileage: Int
    var serviceLogs: [ServiceLog] = []
    var documents: [VehicleDocument] = []
    
    var displayName: String { "\(year) \(make) \(model)" }
    
    var mileageUntilService: Int { nextServiceMileage - currentMileage }
    var isServiceDue: Bool { mileageUntilService <= 1000 }
}

struct ServiceLog: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ServiceType
    var date: Date
    var mileage: Int
    var cost: Double?
    var notes: String?
    var documentURL: URL?
    
    enum ServiceType: String, CaseIterable, Codable {
        case oilChange      = "Oil Change"
        case tires          = "Tires"
        case brakes         = "Brake Service"
        case fullService    = "Full Service"
        case inspection     = "NCT / Inspection"
        case other          = "Other"
        
        var icon: String {
            switch self {
            case .oilChange:   return "drop.fill"
            case .tires:       return "circle.circle"
            case .brakes:      return "exclamationmark.triangle"
            case .fullService: return "wrench.and.screwdriver"
            case .inspection:  return "checkmark.seal"
            case .other:       return "doc.text"
            }
        }
    }
}

struct VehicleDocument: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var url: URL?
}

// MARK: - Insurance

struct InsurancePolicy: Identifiable, Codable {
    var id: UUID = UUID()
    var type: PolicyType
    var provider: String
    var policyNumber: String
    var startDate: Date
    var expiryDate: Date
    var premium: Double?
    var emergencyPhone: String?
    var documentURL: URL?
    
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }
    
    var isExpiringSoon: Bool { daysUntilExpiry <= 30 }
    
    enum PolicyType: String, CaseIterable, Codable {
        case home   = "Home Insurance"
        case car    = "Car Insurance"
        case health = "Health Insurance"
        case travel = "Travel Insurance"
        case life   = "Life Insurance"
        case other  = "Other"
        
        var icon: String {
            switch self {
            case .home:   return "house.fill"
            case .car:    return "car.fill"
            case .health: return "heart.fill"
            case .travel: return "airplane"
            case .life:   return "person.fill"
            case .other:  return "shield.fill"
            }
        }
    }
}

// MARK: - Home Maintenance

struct MaintenanceTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var intervalMonths: Int
    var lastCompleted: Date?
    var notes: String?
    
    var nextDueDate: Date? {
        guard let last = lastCompleted else { return nil }
        return Calendar.current.date(byAdding: .month, value: intervalMonths, to: last)
    }
    
    var isOverdue: Bool {
        guard let due = nextDueDate else { return false }
        return due < Date()
    }
    
    var isDueSoon: Bool {
        guard let due = nextDueDate else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        return days <= 14 && days >= 0
    }
}
