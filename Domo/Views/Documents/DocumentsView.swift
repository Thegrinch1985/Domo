import SwiftUI

struct DocumentsView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddSheet = false
    @State private var showScanner = false
    @State private var searchText = ""
    @State private var selectedCategory: WarrantyItem.ProductCategory? = nil
    
    private var filteredWarranties: [WarrantyItem] {
        store.warranties.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.productName.localizedCaseInsensitiveContains(searchText) ||
                item.storeName.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Category filter chips
                    categoryFilter
                        .padding(.bottom, 8)
                    
                    // Summary strip
                    summaryStrip
                        .padding(.horizontal, DomoTheme.screenPadding)
                        .padding(.bottom, 16)
                    
                    // Warranty list
                    LazyVStack(spacing: 8) {
                        ForEach(filteredWarranties) { item in
                            NavigationLink(destination: WarrantyDetailView(item: item)) {
                                WarrantyRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DomoTheme.screenPadding)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Warranties")
            .searchable(text: $searchText, prompt: "Search warranties")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showScanner = true } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddWarrantyView()
            }
            .fullScreenCover(isPresented: $showScanner) {
                BarcodeScannerView()
            }
            .overlay {
                if filteredWarranties.isEmpty && !searchText.isEmpty {
                    DomoEmptyState(
                        icon: "magnifyingglass",
                        title: "No Results",
                        subtitle: "Try a different search term"
                    )
                } else if store.warranties.isEmpty {
                    DomoEmptyState(
                        icon: "shield.fill",
                        title: "No Warranties Yet",
                        subtitle: "Add your first warranty to start tracking expiration dates.",
                        buttonTitle: "Add Warranty"
                    ) {
                        showAddSheet = true
                    }
                }
            }
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                }
                ForEach(WarrantyItem.ProductCategory.allCases, id: \.self) { cat in
                    FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, DomoTheme.screenPadding)
            .padding(.vertical, 10)
        }
    }
    
    private var summaryStrip: some View {
        HStack(spacing: 0) {
            summaryStat(
                "\(store.warranties.count)",
                label: "Total",
                color: .blue
            )
            Spacer()
            Divider().frame(height: 28)
            Spacer()
            summaryStat(
                "\(store.warranties.filter(\.isExpiringSoon).count)",
                label: "Expiring",
                color: .orange
            )
            Spacer()
            Divider().frame(height: 28)
            Spacer()
            summaryStat(
                "\(store.warranties.filter(\.isExpired).count)",
                label: "Expired",
                color: .red
            )
        }
        .padding(16)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(.white.opacity(0.04), lineWidth: 1)
        )
    }
    
    private func summaryStat(_ value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - WarrantyDetailView

struct WarrantyDetailView: View {
    let item: WarrantyItem
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Hero card
                VStack(spacing: 16) {
                    GradientIcon(
                        icon: item.category.icon,
                        gradient: LinearGradient(
                            colors: [item.statusColor, item.statusColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        size: 64,
                        iconScale: 0.42
                    )
                    
                    Text(item.productName)
                        .font(.title2.bold())
                    
                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.statusColor)
                            .frame(width: 8, height: 8)
                        Text(item.isExpired ? "Expired" : item.isExpiringSoon ? "Expiring Soon" : "Active")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(item.statusColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(item.statusColor.opacity(0.1))
                    .clipShape(Capsule())
                    
                    // Days remaining
                    Text("\(abs(item.daysRemaining)) days \(item.isExpired ? "past" : "remaining")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(DomoTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: DomoTheme.radiusLarge)
                        .strokeBorder(.white.opacity(0.04), lineWidth: 1)
                )
                
                // Details
                VStack(spacing: 1) {
                    detailRow(label: "Store", value: item.storeName)
                    detailRow(label: "Price", value: item.price.formatted(.currency(code: "EUR")))
                    detailRow(label: "Category", value: item.category.rawValue)
                    detailRow(label: "Purchased", value: item.purchaseDate.formatted(date: .long, time: .omitted))
                    detailRow(label: "Expires", value: item.warrantyExpiry.formatted(date: .long, time: .omitted), highlight: item.isExpiringSoon)
                }
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                        .strokeBorder(.white.opacity(0.04), lineWidth: 1)
                )
                
                // Documents section
                if item.documentURL != nil {
                    VStack(spacing: 1) {
                        documentActionRow(icon: "doc.fill", title: "View Receipt", color: .blue)
                        documentActionRow(icon: "book.fill", title: "View Manual", color: .indigo)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                            .strokeBorder(.white.opacity(0.04), lineWidth: 1)
                    )
                }
            }
            .padding(DomoTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationTitle(item.productName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func detailRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(highlight ? .orange : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DomoTheme.cardBackground)
    }
    
    private func documentActionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DomoTheme.cardBackground)
    }
}

// MARK: - AddWarrantyView

struct AddWarrantyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var productName = ""
    @State private var storeName = ""
    @State private var price = ""
    @State private var warrantyYears = 1
    @State private var purchaseDate = Date()
    @State private var category: WarrantyItem.ProductCategory = .electronics
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Product name", text: $productName)
                    TextField("Store", text: $storeName)
                    TextField("Price (€)", text: $price)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(WarrantyItem.ProductCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                } header: {
                    Text("Product Details")
                }
                
                Section("Warranty") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    Stepper("Warranty: \(warrantyYears) year\(warrantyYears > 1 ? "s" : "")",
                            value: $warrantyYears, in: 1...10)
                }
                
                Section {
                    Label("Scan Receipt", systemImage: "camera.viewfinder")
                        .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Add Warranty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(productName.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let item = WarrantyItem(
            productName: productName,
            storeName: storeName,
            purchaseDate: purchaseDate,
            warrantyYears: warrantyYears,
            price: Double(price) ?? 0,
            category: category
        )
        store.addWarranty(item)
        dismiss()
    }
}

#Preview {
    DocumentsView()
        .environmentObject(DomoStore())
        .preferredColorScheme(.dark)
}
