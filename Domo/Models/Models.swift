import Foundation
import SwiftUI
import SwiftData

// MARK: - Warranty

@Model
final class WarrantyItem {
    var id: UUID
    var productName: String
    var storeName: String
    var purchaseDate: Date
    var warrantyYears: Int
    var price: Double
    var categoryRaw: String
    var documentURL: URL?
    var reminderDate: Date?
    var receiptImageData: Data?
    var asset: Asset?
    
    init(
        id: UUID = UUID(),
        productName: String,
        storeName: String,
        purchaseDate: Date,
        warrantyYears: Int,
        price: Double,
        category: ProductCategory,
        documentURL: URL? = nil,
        reminderDate: Date? = nil,
        receiptImageData: Data? = nil
    ) {
        self.id = id
        self.productName = productName
        self.storeName = storeName
        self.purchaseDate = purchaseDate
        self.warrantyYears = warrantyYears
        self.price = price
        self.categoryRaw = category.rawValue
        self.documentURL = documentURL
        self.reminderDate = reminderDate
        self.receiptImageData = receiptImageData
    }
    
    var category: ProductCategory {
        get { ProductCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    var warrantyExpiry: Date {
        Calendar.current.date(byAdding: .year, value: warrantyYears, to: purchaseDate) ?? purchaseDate
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: warrantyExpiry).day ?? 0
    }
    
    var isExpiringSoon: Bool { daysRemaining <= 30 && daysRemaining >= 0 }
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

@Model
final class Subscription {
    var id: UUID
    var name: String
    var price: Double
    var billingCycleRaw: String
    var renewalDate: Date
    var categoryRaw: String
    var iconName: String
    var colorHex: String
    var isActive: Bool
    var reminderDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        price: Double,
        billingCycle: BillingCycle,
        renewalDate: Date,
        category: SubscriptionCategory,
        iconName: String,
        colorHex: String,
        isActive: Bool = true,
        reminderDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.billingCycleRaw = billingCycle.rawValue
        self.renewalDate = renewalDate
        self.categoryRaw = category.rawValue
        self.iconName = iconName
        self.colorHex = colorHex
        self.isActive = isActive
        self.reminderDate = reminderDate
    }
    
    var billingCycle: BillingCycle {
        get { BillingCycle(rawValue: billingCycleRaw) ?? .monthly }
        set { billingCycleRaw = newValue.rawValue }
    }
    
    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
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

@Model
final class Vehicle {
    var id: UUID
    var make: String
    var model: String
    var year: Int
    var plate: String
    var currentMileage: Int
    var nextServiceMileage: Int
    var insuranceRenewalDate: Date?
    var taxExpiryDate: Date?
    var nctExpiryDate: Date?
    @Relationship(deleteRule: .cascade) var serviceLogs: [ServiceLog]
    
    init(
        id: UUID = UUID(),
        make: String,
        model: String,
        year: Int,
        plate: String,
        currentMileage: Int,
        nextServiceMileage: Int,
        insuranceRenewalDate: Date? = nil,
        taxExpiryDate: Date? = nil,
        nctExpiryDate: Date? = nil,
        serviceLogs: [ServiceLog] = []
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.plate = plate
        self.currentMileage = currentMileage
        self.nextServiceMileage = nextServiceMileage
        self.insuranceRenewalDate = insuranceRenewalDate
        self.taxExpiryDate = taxExpiryDate
        self.nctExpiryDate = nctExpiryDate
        self.serviceLogs = serviceLogs
    }
    
    var displayName: String { "\(year) \(make) \(model)" }
    var mileageUntilService: Int { nextServiceMileage - currentMileage }
    var isServiceDue: Bool { mileageUntilService <= 1000 }
    
    var lastServiceDate: Date? {
        serviceLogs.sorted { $0.date > $1.date }.first?.date
    }
}

@Model
final class ServiceLog {
    var id: UUID
    var typeRaw: String
    var date: Date
    var mileage: Int
    var cost: Double?
    var notes: String?
    var documentURL: URL?
    var vehicle: Vehicle?
    
    init(
        id: UUID = UUID(),
        type: ServiceType,
        date: Date,
        mileage: Int,
        cost: Double? = nil,
        notes: String? = nil,
        documentURL: URL? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.date = date
        self.mileage = mileage
        self.cost = cost
        self.notes = notes
        self.documentURL = documentURL
    }
    
    var type: ServiceType {
        get { ServiceType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    
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

// MARK: - Insurance

@Model
final class InsurancePolicy {
    var id: UUID
    var typeRaw: String
    var provider: String
    var policyNumber: String
    var startDate: Date
    var expiryDate: Date
    var premium: Double?
    var emergencyPhone: String?
    var documentURL: URL?
    var reminderDate: Date?
    var asset: Asset?
    
    init(
        id: UUID = UUID(),
        type: PolicyType,
        provider: String,
        policyNumber: String,
        startDate: Date,
        expiryDate: Date,
        premium: Double? = nil,
        emergencyPhone: String? = nil,
        documentURL: URL? = nil,
        reminderDate: Date? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.provider = provider
        self.policyNumber = policyNumber
        self.startDate = startDate
        self.expiryDate = expiryDate
        self.premium = premium
        self.emergencyPhone = emergencyPhone
        self.documentURL = documentURL
        self.reminderDate = reminderDate
    }
    
    var type: PolicyType {
        get { PolicyType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }
    
    var isExpiringSoon: Bool { daysUntilExpiry <= 30 && daysUntilExpiry >= 0 }
    
    enum PolicyType: String, CaseIterable, Codable, Hashable {
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

@Model
final class MaintenanceTask {
    var id: UUID
    var title: String
    var intervalMonths: Int
    var lastCompleted: Date?
    var notes: String?
    var reminderDate: Date?
    var estimatedCost: Double
    var asset: Asset?
    
    init(
        id: UUID = UUID(),
        title: String,
        intervalMonths: Int,
        lastCompleted: Date? = nil,
        notes: String? = nil,
        reminderDate: Date? = nil,
        estimatedCost: Double = 0
    ) {
        self.id = id
        self.title = title
        self.intervalMonths = intervalMonths
        self.lastCompleted = lastCompleted
        self.notes = notes
        self.reminderDate = reminderDate
        self.estimatedCost = estimatedCost
    }
    
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

// MARK: - Receipt

@Model
final class Receipt {
    var id: UUID
    var title: String
    var categoryRaw: String
    var purchaseDate: Date
    var warrantyMonths: Int
    var receiptImage: Data?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        category: ReceiptCategory = .general,
        purchaseDate: Date = .now,
        warrantyMonths: Int = 12,
        receiptImage: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.purchaseDate = purchaseDate
        self.warrantyMonths = warrantyMonths
        self.receiptImage = receiptImage
        self.createdAt = createdAt
    }
    
    var category: ReceiptCategory {
        get { ReceiptCategory(rawValue: categoryRaw) ?? .general }
        set { categoryRaw = newValue.rawValue }
    }
    
    var warrantyExpiry: Date {
        Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) ?? purchaseDate
    }
    
    var warrantyDaysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: warrantyExpiry).day ?? 0
    }
    
    var isWarrantyExpired: Bool { warrantyDaysRemaining < 0 }
    
    enum ReceiptCategory: String, CaseIterable, Identifiable, Codable {
        case general     = "General"
        case electronics = "Electronics"
        case groceries   = "Groceries"
        case clothing    = "Clothing"
        case homeGarden  = "Home & Garden"
        case health      = "Health"
        case dining      = "Dining"
        case other       = "Other"
        
        var id: String { rawValue }
        
        var label: String { rawValue }
        
        var icon: String {
            switch self {
            case .general:     return "doc.text"
            case .electronics: return "desktopcomputer"
            case .groceries:   return "cart"
            case .clothing:    return "tshirt"
            case .homeGarden:  return "house"
            case .health:      return "heart"
            case .dining:      return "fork.knife"
            case .other:       return "ellipsis.circle"
            }
        }
    }
}

// MARK: - Asset

@Model
final class Asset {
    var id: UUID
    var name: String
    var categoryRaw: String
    var brand: String
    var modelName: String
    var serialNumber: String
    var purchaseDate: Date
    var purchasePrice: Double
    var notes: String
    var createdAt: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \WarrantyItem.asset) var warranties: [WarrantyItem]
    @Relationship(deleteRule: .nullify, inverse: \MaintenanceTask.asset) var maintenanceTasks: [MaintenanceTask]
    @Relationship(deleteRule: .nullify, inverse: \InsurancePolicy.asset) var insurancePolicies: [InsurancePolicy]
    
    init(
        id: UUID = UUID(),
        name: String,
        category: AssetCategory = .other,
        brand: String = "",
        modelName: String = "",
        serialNumber: String = "",
        purchaseDate: Date = .now,
        purchasePrice: Double = 0,
        notes: String = "",
        warranties: [WarrantyItem] = [],
        maintenanceTasks: [MaintenanceTask] = [],
        insurancePolicies: [InsurancePolicy] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.brand = brand
        self.modelName = modelName
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.notes = notes
        self.warranties = warranties
        self.maintenanceTasks = maintenanceTasks
        self.insurancePolicies = insurancePolicies
        self.createdAt = createdAt
    }
    
    var category: AssetCategory {
        get { AssetCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    var displayLabel: String {
        [brand, name].filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    var totalValue: Double { purchasePrice }
    
    var activeWarrantyCount: Int {
        warranties.filter { !$0.isExpired }.count
    }
    
    enum AssetCategory: String, CaseIterable, Identifiable, Codable {
        case electronics = "Electronics"
        case appliances  = "Appliances"
        case furniture   = "Furniture"
        case automotive  = "Automotive"
        case homeGarden  = "Home & Garden"
        case sports      = "Sports & Outdoors"
        case clothing    = "Clothing"
        case jewelry     = "Jewelry"
        case tools       = "Tools"
        case other       = "Other"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .electronics: return "laptopcomputer"
            case .appliances:  return "washer"
            case .furniture:   return "sofa"
            case .automotive:  return "car"
            case .homeGarden:  return "leaf"
            case .sports:      return "figure.run"
            case .clothing:    return "tshirt"
            case .jewelry:     return "sparkles"
            case .tools:       return "wrench.and.screwdriver"
            case .other:       return "archivebox"
            }
        }
        
        var color: Color {
            switch self {
            case .electronics: return .blue
            case .appliances:  return .orange
            case .furniture:   return .brown
            case .automotive:  return .red
            case .homeGarden:  return .green
            case .sports:      return .teal
            case .clothing:    return .purple
            case .jewelry:     return .pink
            case .tools:       return .gray
            case .other:       return .indigo
            }
        }
    }
}

// MARK: - User Account (stored in SwiftData)

@Model
final class UserAccount {
    var id: UUID
    var fullName: String
    var email: String
    var createdAt: Date
    var appleUserID: String?
    
    init(
        id: UUID = UUID(),
        fullName: String,
        email: String,
        createdAt: Date = .now,
        appleUserID: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.createdAt = createdAt
        self.appleUserID = appleUserID
    }
    
    var initials: String {
        let parts = fullName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
}
