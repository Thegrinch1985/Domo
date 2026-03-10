import Foundation
import SwiftUI

// MARK: - WarrantyItem Samples

extension WarrantyItem {
    static let samples: [WarrantyItem] = [
        WarrantyItem(
            productName: "MacBook Pro 16\"",
            storeName: "Apple Store",
            purchaseDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
            warrantyYears: 1,
            price: 2799,
            category: .electronics
        ),
        WarrantyItem(
            productName: "Samsung TV",
            storeName: "Harvey Norman",
            purchaseDate: Calendar.current.date(byAdding: .month, value: -20, to: Date())!,
            warrantyYears: 2,
            price: 1199,
            category: .electronics
        ),
        WarrantyItem(
            productName: "Bosch Dishwasher",
            storeName: "DID Electrical",
            purchaseDate: Calendar.current.date(byAdding: .month, value: -4, to: Date())!,
            warrantyYears: 2,
            price: 849,
            category: .appliances
        ),
        WarrantyItem(
            productName: "iPhone 15 Pro",
            storeName: "Apple Store",
            purchaseDate: Calendar.current.date(byAdding: .day, value: -340, to: Date())!,
            warrantyYears: 1,
            price: 1199,
            category: .electronics
        ),
    ]
}

// MARK: - Subscription Samples

extension Subscription {
    static let samples: [Subscription] = [
        Subscription(
            name: "Netflix",
            price: 15.99,
            billingCycle: .monthly,
            renewalDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!,
            category: .entertainment,
            iconName: "play.rectangle.fill",
            colorHex: "#E50914"
        ),
        Subscription(
            name: "Spotify",
            price: 9.99,
            billingCycle: .monthly,
            renewalDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
            category: .entertainment,
            iconName: "music.note",
            colorHex: "#1DB954"
        ),
        Subscription(
            name: "iCloud+",
            price: 2.99,
            billingCycle: .monthly,
            renewalDate: Calendar.current.date(byAdding: .day, value: 22, to: Date())!,
            category: .utilities,
            iconName: "cloud.fill",
            colorHex: "#007AFF"
        ),
        Subscription(
            name: "Adobe CC",
            price: 54.99,
            billingCycle: .monthly,
            renewalDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            category: .productivity,
            iconName: "paintbrush.fill",
            colorHex: "#FF0000"
        ),
        Subscription(
            name: "Gym",
            price: 39.99,
            billingCycle: .monthly,
            renewalDate: Calendar.current.date(byAdding: .day, value: 22, to: Date())!,
            category: .health,
            iconName: "figure.strengthtraining.traditional",
            colorHex: "#FF9F0A"
        ),
    ]
}

// MARK: - Vehicle Samples

extension Vehicle {
    static let samples: [Vehicle] = [
        Vehicle(
            make: "BMW",
            model: "3 Series",
            year: 2021,
            plate: "192-D-4821",
            currentMileage: 72400,
            nextServiceMileage: 73000,
            serviceLogs: ServiceLog.samples
        )
    ]
}

extension ServiceLog {
    static let samples: [ServiceLog] = [
        ServiceLog(
            type: .oilChange,
            date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            mileage: 71200,
            cost: 89.00
        ),
        ServiceLog(
            type: .brakes,
            date: Calendar.current.date(byAdding: .month, value: -7, to: Date())!,
            mileage: 68500,
            cost: 310.00
        ),
        ServiceLog(
            type: .tires,
            date: Calendar.current.date(byAdding: .month, value: -17, to: Date())!,
            mileage: 63100,
            cost: 480.00
        ),
        ServiceLog(
            type: .fullService,
            date: Calendar.current.date(byAdding: .month, value: -24, to: Date())!,
            mileage: 58000,
            cost: 650.00
        ),
    ]
}

// MARK: - InsurancePolicy Samples

extension InsurancePolicy {
    static let samples: [InsurancePolicy] = [
        InsurancePolicy(
            type: .home,
            provider: "AXA",
            policyNumber: "HM-2024-882901",
            startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
            expiryDate: Calendar.current.date(byAdding: .month, value: 9, to: Date())!,
            premium: 650,
            emergencyPhone: "1800 222 333"
        ),
        InsurancePolicy(
            type: .car,
            provider: "Allianz",
            policyNumber: "CA-2025-441209",
            startDate: Calendar.current.date(byAdding: .month, value: -4, to: Date())!,
            expiryDate: Calendar.current.date(byAdding: .month, value: 8, to: Date())!,
            premium: 980,
            emergencyPhone: "1800 444 555"
        ),
        InsurancePolicy(
            type: .health,
            provider: "VHI",
            policyNumber: "VH-2024-100234",
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            expiryDate: Calendar.current.date(byAdding: .month, value: 10, to: Date())!,
            premium: 1200
        ),
    ]
}

// MARK: - MaintenanceTask Samples

extension MaintenanceTask {
    static let samples: [MaintenanceTask] = [
        MaintenanceTask(
            title: "Boiler Service",
            intervalMonths: 12,
            lastCompleted: Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        ),
        MaintenanceTask(
            title: "Smoke Alarm Battery",
            intervalMonths: 6,
            lastCompleted: Calendar.current.date(byAdding: .month, value: -5, to: Date())!
        ),
        MaintenanceTask(
            title: "Water Filter",
            intervalMonths: 3,
            lastCompleted: Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        ),
        MaintenanceTask(
            title: "Clean Gutters",
            intervalMonths: 12,
            lastCompleted: Calendar.current.date(byAdding: .month, value: -10, to: Date())!
        ),
    ]
}
