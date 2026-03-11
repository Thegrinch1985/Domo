import SwiftUI
import SwiftData

// MARK: - GlobalSearchView

struct GlobalSearchView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    emptyPrompt
                } else if hasNoResults {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Assets, documents, subscriptions…")
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            if !matchingAssets.isEmpty {
                Section {
                    ForEach(matchingAssets) { asset in
                        NavigationLink(destination: AssetDetailView(asset: asset)) {
                            resultRow(
                                icon: asset.category.icon,
                                color: asset.category.color,
                                title: asset.displayLabel,
                                subtitle: asset.category.rawValue
                            )
                        }
                    }
                } header: {
                    sectionHeader(icon: "cube.box.fill", title: "Assets", count: matchingAssets.count)
                }
            }

            if !matchingDocuments.isEmpty {
                Section {
                    ForEach(matchingDocuments) { doc in
                        resultRow(
                            icon: "doc.text.fill",
                            color: .purple,
                            title: doc.title,
                            subtitle: doc.category
                        )
                    }
                } header: {
                    sectionHeader(icon: "doc.text.fill", title: "Documents", count: matchingDocuments.count)
                }
            }

            if !matchingWarranties.isEmpty {
                Section {
                    ForEach(matchingWarranties) { item in
                        NavigationLink(destination: WarrantyDetailView(item: item)) {
                            resultRow(
                                icon: item.category.icon,
                                color: item.statusColor,
                                title: item.productName,
                                subtitle: "\(item.storeName) · \(item.daysRemaining)d left"
                            )
                        }
                    }
                } header: {
                    sectionHeader(icon: "shield.lefthalf.filled", title: "Warranties", count: matchingWarranties.count)
                }
            }

            if !matchingSubscriptions.isEmpty {
                Section {
                    ForEach(matchingSubscriptions) { sub in
                        resultRow(
                            icon: sub.iconName,
                            color: sub.isActive ? .blue : .secondary,
                            title: sub.name,
                            subtitle: "\(sub.billingCycle.rawValue) · \(sub.price.formatted(.currency(code: "EUR")))"
                        )
                    }
                } header: {
                    sectionHeader(icon: "arrow.triangle.2.circlepath", title: "Subscriptions", count: matchingSubscriptions.count)
                }
            }

            if !matchingInsurance.isEmpty {
                Section {
                    ForEach(matchingInsurance) { policy in
                        NavigationLink(destination: PolicyDetailView(policy: policy)) {
                            resultRow(
                                icon: policy.type.icon,
                                color: policy.isExpiringSoon ? .orange : .blue,
                                title: "\(policy.provider) — \(policy.type.rawValue)",
                                subtitle: "Expires \(policy.expiryDate.formatted(date: .abbreviated, time: .omitted))"
                            )
                        }
                    }
                } header: {
                    sectionHeader(icon: "lock.shield.fill", title: "Insurance", count: matchingInsurance.count)
                }
            }

            if !matchingMaintenance.isEmpty {
                Section {
                    ForEach(matchingMaintenance) { task in
                        resultRow(
                            icon: "wrench.and.screwdriver.fill",
                            color: task.isOverdue ? .red : (task.isDueSoon ? .orange : .teal),
                            title: task.title,
                            subtitle: task.nextDueDate.map { "Due \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "No schedule"
                        )
                    }
                } header: {
                    sectionHeader(icon: "wrench.and.screwdriver.fill", title: "Maintenance", count: matchingMaintenance.count)
                }
            }

            if !matchingVehicles.isEmpty {
                Section {
                    ForEach(matchingVehicles) { vehicle in
                        resultRow(
                            icon: "car.fill",
                            color: vehicle.isServiceDue ? .orange : .green,
                            title: vehicle.displayName,
                            subtitle: vehicle.plate
                        )
                    }
                } header: {
                    sectionHeader(icon: "car.fill", title: "Vehicles", count: matchingVehicles.count)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: searchText)
    }

    // MARK: - Empty / No Results

    private var emptyPrompt: some View {
        ContentUnavailableView(
            "Search Everything",
            systemImage: "magnifyingglass",
            description: Text("Find assets, documents, subscriptions, warranties, vehicles and more.")
        )
    }

    private var noResultsView: some View {
        ContentUnavailableView.search(text: searchText)
    }

    private var hasNoResults: Bool {
        matchingAssets.isEmpty &&
        matchingDocuments.isEmpty &&
        matchingWarranties.isEmpty &&
        matchingSubscriptions.isEmpty &&
        matchingInsurance.isEmpty &&
        matchingMaintenance.isEmpty &&
        matchingVehicles.isEmpty
    }

    // MARK: - Row Components

    private func resultRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func sectionHeader(icon: String, title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
            Spacer()
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
    }

    // MARK: - SwiftData Queries

    private var query: String { searchText.trimmingCharacters(in: .whitespaces) }

    private var matchingAssets: [Asset] {
        guard !query.isEmpty else { return [] }
        let q = query
        var descriptor = FetchDescriptor<Asset>(
            predicate: #Predicate<Asset> {
                $0.name.localizedStandardContains(q) ||
                $0.brand.localizedStandardContains(q) ||
                $0.modelName.localizedStandardContains(q) ||
                $0.serialNumber.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.fetchLimit = 20
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var matchingDocuments: [Document] {
        guard !query.isEmpty else { return [] }
        let q = query
        var descriptor = FetchDescriptor<Document>(
            predicate: #Predicate<Document> {
                $0.title.localizedStandardContains(q) ||
                $0.category.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var matchingWarranties: [WarrantyItem] {
        guard !query.isEmpty else { return [] }
        let q = query
        var descriptor = FetchDescriptor<WarrantyItem>(
            predicate: #Predicate<WarrantyItem> {
                $0.productName.localizedStandardContains(q) ||
                $0.storeName.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var matchingSubscriptions: [Subscription] {
        guard !query.isEmpty else { return [] }
        let q = query
        var descriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate<Subscription> {
                $0.name.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.fetchLimit = 20
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var matchingInsurance: [InsurancePolicy] {
        guard !query.isEmpty else { return [] }
        let q = query
        var descriptor = FetchDescriptor<InsurancePolicy>(
            predicate: #Predicate<InsurancePolicy> {
                $0.provider.localizedStandardContains(q) ||
                $0.policyNumber.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.expiryDate)]
        )
        descriptor.fetchLimit = 20
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var matchingMaintenance: [MaintenanceTask] {
        guard !query.isEmpty else { return [] }
        let q = query
        var descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate<MaintenanceTask> {
                $0.title.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.title)]
        )
        descriptor.fetchLimit = 20
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var matchingVehicles: [Vehicle] {
        guard !query.isEmpty else { return [] }
        let q = query
        var descriptor = FetchDescriptor<Vehicle>(
            predicate: #Predicate<Vehicle> {
                $0.make.localizedStandardContains(q) ||
                $0.model.localizedStandardContains(q) ||
                $0.plate.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Preview

#Preview {
    GlobalSearchView()
        .modelContainer(for: [
            Asset.self, Document.self, WarrantyItem.self,
            Subscription.self, InsurancePolicy.self,
            MaintenanceTask.self, Vehicle.self, ServiceLog.self
        ])
}
