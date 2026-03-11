import SwiftUI
import SwiftData

struct AssetDetailView: View {
    
    @EnvironmentObject private var store: DomoStore
    @Environment(\.dismiss) private var dismiss
    
    let asset: Asset
    
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var showLinkWarranty = false
    @State private var showLinkPolicy = false
    @State private var showLinkTask = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero header
                heroHeader
                
                // Content sections
                VStack(spacing: DomoTheme.sectionSpacing) {
                    detailsSection
                    warrantiesSection
                    documentsSection
                    maintenanceSection
                    insuranceSection
                }
                .padding(.horizontal, DomoTheme.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("Edit Asset", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete Asset", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditAssetView(asset: asset)
        }
        .sheet(isPresented: $showLinkWarranty) {
            LinkItemSheet(title: "Link Warranty", items: store.warranties.filter { $0.asset == nil }) { item in
                item.asset = asset
                store.refresh()
            } label: { (w: WarrantyItem) in
                Label(w.productName, systemImage: "shield.lefthalf.filled")
            }
        }
        .sheet(isPresented: $showLinkPolicy) {
            LinkItemSheet(title: "Link Policy", items: store.insurancePolicies.filter { $0.asset == nil }) { item in
                item.asset = asset
                store.refresh()
            } label: { (p: InsurancePolicy) in
                Label(p.provider, systemImage: "shield.checkered")
            }
        }
        .sheet(isPresented: $showLinkTask) {
            LinkItemSheet(title: "Link Task", items: store.maintenanceTasks.filter { $0.asset == nil }) { item in
                item.asset = asset
                store.refresh()
            } label: { (t: MaintenanceTask) in
                Label(t.title, systemImage: "wrench.and.screwdriver")
            }
        }
        .alert("Delete Asset?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteAsset(asset)
                dismiss()
            }
        } message: {
            Text("This will remove the asset but keep any linked warranties, documents, and policies.")
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(spacing: 16) {
            // Large icon
            ZStack {
                Circle()
                    .fill(asset.category.color.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: asset.category.icon)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(asset.category.color)
            }
            
            // Name & brand
            VStack(spacing: 4) {
                Text(asset.name)
                    .font(.title2.bold())
                
                if !asset.brand.isEmpty || !asset.modelName.isEmpty {
                    Text([asset.brand, asset.modelName].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Quick stats
            HStack(spacing: 0) {
                quickStat(
                    value: asset.purchasePrice > 0 ? asset.purchasePrice.formatted(.currency(code: "EUR")) : "—",
                    label: "Value"
                )
                Divider().frame(height: 32)
                quickStat(
                    value: asset.purchaseDate.formatted(date: .abbreviated, time: .omitted),
                    label: "Purchased"
                )
                Divider().frame(height: 32)
                quickStat(
                    value: "\(asset.warranties.count + store.documents(forAssetID: asset.id).count + asset.maintenanceTasks.count + asset.insurancePolicies.count)",
                    label: "Linked Items"
                )
            }
            .domoCard(padding: 14)
        }
        .padding(.horizontal, DomoTheme.screenPadding)
        .padding(.top, 8)
    }
    
    private func quickStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Details")
            
            VStack(spacing: 0) {
                if !asset.serialNumber.isEmpty {
                    detailRow(label: "Serial Number", value: asset.serialNumber, icon: "number")
                    Divider().padding(.leading, 44)
                }
                detailRow(label: "Category", value: asset.category.rawValue, icon: asset.category.icon)
                if !asset.notes.isEmpty {
                    Divider().padding(.leading, 44)
                    detailRow(label: "Notes", value: asset.notes, icon: "note.text")
                }
            }
            .background(DomoTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                    .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
        }
    }
    
    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Warranties Section
    
    private var warrantiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Warranties")
                Spacer()
                Button { showLinkWarranty = true } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }
            }
            
            if asset.warranties.isEmpty {
                emptyLinkedCard(icon: "shield.lefthalf.filled", text: "No linked warranties")
            } else {
                VStack(spacing: 8) {
                    ForEach(asset.warranties) { warranty in
                        linkedWarrantyRow(warranty)
                    }
                }
            }
        }
    }
    
    private func linkedWarrantyRow(_ item: WarrantyItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.statusColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.productName)
                    .font(.subheadline.weight(.medium))
                Text("Expires \(item.warrantyExpiry.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(item.daysRemaining)d")
                .font(.caption.bold())
                .foregroundStyle(item.statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                item.asset = nil
                store.refresh()
            } label: {
                Label("Unlink", systemImage: "link.badge.plus")
            }
        }
    }
    
    // MARK: - Documents Section
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Documents")
            
            let docs = store.documents(forAssetID: asset.id)
            if docs.isEmpty {
                emptyLinkedCard(icon: "doc", text: "No linked documents")
            } else {
                VStack(spacing: 8) {
                    ForEach(docs) { doc in
                        linkedDocumentRow(doc)
                    }
                }
            }
        }
    }
    
    private func linkedDocumentRow(_ doc: Document) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.title)
                    .font(.subheadline.weight(.medium))
                Text(doc.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                doc.linkedAssetID = nil
                store.refresh()
            } label: {
                Label("Unlink", systemImage: "link.badge.plus")
            }
        }
    }
    
    // MARK: - Maintenance Section
    
    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Maintenance")
                Spacer()
                Button { showLinkTask = true } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }
            }
            
            if asset.maintenanceTasks.isEmpty {
                emptyLinkedCard(icon: "wrench.and.screwdriver", text: "No linked tasks")
            } else {
                VStack(spacing: 8) {
                    ForEach(asset.maintenanceTasks) { task in
                        linkedTaskRow(task)
                    }
                }
            }
        }
    }
    
    private func linkedTaskRow(_ task: MaintenanceTask) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(task.isOverdue ? .red : task.isDueSoon ? .orange : .green)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                if let due = task.nextDueDate {
                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                } else {
                    Text("Not yet completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                task.asset = nil
                store.refresh()
            } label: {
                Label("Unlink", systemImage: "link.badge.plus")
            }
        }
    }
    
    // MARK: - Insurance Section
    
    private var insuranceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Insurance")
                Spacer()
                Button { showLinkPolicy = true } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }
            }
            
            if asset.insurancePolicies.isEmpty {
                emptyLinkedCard(icon: "shield.checkered", text: "No linked policies")
            } else {
                VStack(spacing: 8) {
                    ForEach(asset.insurancePolicies) { policy in
                        linkedPolicyRow(policy)
                    }
                }
            }
        }
    }
    
    private func linkedPolicyRow(_ policy: InsurancePolicy) -> some View {
        HStack(spacing: 12) {
            Image(systemName: policy.type.icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(policy.provider)
                    .font(.subheadline.weight(.medium))
                Text("Expires \(policy.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(policy.isExpiringSoon ? .orange : .secondary)
            }
            Spacer()
            if policy.isExpiringSoon {
                Text("\(policy.daysUntilExpiry)d")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                policy.asset = nil
                store.refresh()
            } label: {
                Label("Unlink", systemImage: "link.badge.plus")
            }
        }
    }
    
    // MARK: - Empty Card
    
    private func emptyLinkedCard(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Link Item Sheet (Generic)

struct LinkItemSheet<Item: PersistentModel & Identifiable, ItemLabel: View>: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let items: [Item]
    let onLink: (Item) -> Void
    let label: (Item) -> ItemLabel
    
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    DomoEmptyState(
                        icon: "link",
                        title: "Nothing to Link",
                        subtitle: "All items are already linked to an asset."
                    )
                } else {
                    List(items) { item in
                        Button {
                            onLink(item)
                            dismiss()
                        } label: {
                            label(item)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Edit Asset View

struct EditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    let asset: Asset
    
    @State private var name: String
    @State private var brand: String
    @State private var modelName: String
    @State private var serialNumber: String
    @State private var selectedCategory: Asset.AssetCategory
    @State private var purchaseDate: Date
    @State private var purchasePrice: Double
    @State private var notes: String
    
    init(asset: Asset) {
        self.asset = asset
        _name = State(initialValue: asset.name)
        _brand = State(initialValue: asset.brand)
        _modelName = State(initialValue: asset.modelName)
        _serialNumber = State(initialValue: asset.serialNumber)
        _selectedCategory = State(initialValue: asset.category)
        _purchaseDate = State(initialValue: asset.purchaseDate)
        _purchasePrice = State(initialValue: asset.purchasePrice)
        _notes = State(initialValue: asset.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Information") {
                    TextField("Name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $modelName)
                    TextField("Serial Number", text: $serialNumber)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Asset.AssetCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }
                
                Section("Purchase") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0.00", value: $purchasePrice, format: .currency(code: "EUR"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        asset.name = name.trimmingCharacters(in: .whitespaces)
        asset.brand = brand.trimmingCharacters(in: .whitespaces)
        asset.modelName = modelName.trimmingCharacters(in: .whitespaces)
        asset.serialNumber = serialNumber.trimmingCharacters(in: .whitespaces)
        asset.category = selectedCategory
        asset.purchaseDate = purchaseDate
        asset.purchasePrice = purchasePrice
        asset.notes = notes.trimmingCharacters(in: .whitespaces)
        store.refresh()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AssetDetailView(asset: Asset(name: "MacBook Pro", category: .electronics, brand: "Apple", modelName: "M3 Max"))
            .environmentObject(DomoStore())
    }
}
