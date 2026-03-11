import SwiftUI

struct AssetsView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: Asset.AssetCategory? = nil
    @State private var viewMode: ViewMode = .grid
    
    enum ViewMode: String, CaseIterable {
        case grid, list
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    private var filteredAssets: [Asset] {
        store.assets.filter { asset in
            let matchesSearch = searchText.isEmpty ||
                asset.name.localizedCaseInsensitiveContains(searchText) ||
                asset.brand.localizedCaseInsensitiveContains(searchText) ||
                asset.serialNumber.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || asset.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Category filter
                    categoryFilter
                        .padding(.bottom, 8)
                    
                    // Summary
                    summaryStrip
                        .padding(.horizontal, DomoTheme.screenPadding)
                        .padding(.bottom, 16)
                    
                    // Assets collection
                    switch viewMode {
                    case .grid:
                        assetGrid
                    case .list:
                        assetList
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Assets")
            .searchable(text: $searchText, prompt: "Search assets")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("View", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Image(systemName: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
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
                AddAssetView()
            }
            .overlay {
                if filteredAssets.isEmpty && !searchText.isEmpty {
                    DomoEmptyState(
                        icon: "magnifyingglass",
                        title: "No Results",
                        subtitle: "Try a different search term"
                    )
                } else if store.assets.isEmpty {
                    DomoEmptyState(
                        icon: "cube.box",
                        title: "No Assets Yet",
                        subtitle: "Add your first asset to start tracking your belongings.",
                        buttonTitle: "Add Asset",
                        action: { showAddSheet = true },
                        suggestions: [
                            .init(icon: "tv", label: "TV"),
                            .init(icon: "laptopcomputer", label: "Laptop"),
                            .init(icon: "iphone", label: "Phone"),
                            .init(icon: "car", label: "Car"),
                            .init(icon: "washer", label: "Appliance"),
                        ]
                    ) { _ in
                        showAddSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                }
                ForEach(Asset.AssetCategory.allCases) { cat in
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
    
    // MARK: - Summary Strip
    
    private var summaryStrip: some View {
        HStack(spacing: 20) {
            summaryItem(
                value: "\(filteredAssets.count)",
                label: "Items"
            )
            Divider().frame(height: 28)
            summaryItem(
                value: totalValue,
                label: "Total Value"
            )
            Divider().frame(height: 28)
            summaryItem(
                value: "\(filteredAssets.flatMap(\.warranties).filter { !$0.isExpired }.count)",
                label: "Active Warranties"
            )
        }
        .frame(maxWidth: .infinity)
        .domoCard(padding: 14)
    }
    
    private func summaryItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var totalValue: String {
        let total = filteredAssets.reduce(0) { $0 + $1.purchasePrice }
        return total > 0 ? total.formatted(.currency(code: "EUR")) : "—"
    }
    
    // MARK: - Grid View
    
    private var assetGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredAssets) { asset in
                NavigationLink(destination: AssetDetailView(asset: asset)) {
                    AssetGridCard(asset: asset)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DomoTheme.screenPadding)
        .animation(.easeInOut(duration: 0.25), value: filteredAssets.count)
    }
    
    // MARK: - List View
    
    private var assetList: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredAssets) { asset in
                NavigationLink(destination: AssetDetailView(asset: asset)) {
                    AssetListRow(asset: asset)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DomoTheme.screenPadding)
        .animation(.easeInOut(duration: 0.25), value: filteredAssets.count)
    }
}

// MARK: - Asset Grid Card

private struct AssetGridCard: View {
    let asset: Asset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(asset.category.color.opacity(0.12))
                    .frame(height: 80)
                Image(systemName: asset.category.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(asset.category.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                
                if !asset.brand.isEmpty {
                    Text(asset.brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    if asset.purchasePrice > 0 {
                        Text(asset.purchasePrice.formatted(.currency(code: "EUR")))
                            .font(.caption.bold())
                            .foregroundStyle(asset.category.color)
                    }
                    Spacer()
                    if !asset.warranties.isEmpty {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .domoCard()
    }
}

// MARK: - Asset List Row

private struct AssetListRow: View {
    let asset: Asset
    @EnvironmentObject private var store: DomoStore
    
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(asset.category.color.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: asset.category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(asset.category.color)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if !asset.brand.isEmpty {
                        Text(asset.brand)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    if !asset.brand.isEmpty && !asset.modelName.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                    }
                    if !asset.modelName.isEmpty {
                        Text(asset.modelName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Right info
            VStack(alignment: .trailing, spacing: 4) {
                if asset.purchasePrice > 0 {
                    Text(asset.purchasePrice.formatted(.currency(code: "EUR")))
                        .font(.caption.bold())
                }
                HStack(spacing: 4) {
                    if !asset.warranties.isEmpty {
                        Label("\(asset.activeWarrantyCount)", systemImage: "shield.lefthalf.filled")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    let docCount = store.documents(forAssetID: asset.id).count
                    if docCount > 0 {
                        Label("\(docCount)", systemImage: "doc")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview {
    AssetsView()
        .environmentObject(DomoStore())
}
