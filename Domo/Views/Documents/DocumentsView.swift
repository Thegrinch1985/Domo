import SwiftUI

struct DocumentsView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddSheet = false
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
            List {
                // Category filter chips
                categoryFilter
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                
                // Warranty list
                ForEach(filteredWarranties) { item in
                    NavigationLink(destination: WarrantyDetailView(item: item)) {
                        WarrantyRow(item: item)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: store.deleteWarranty)
            }
            .listStyle(.plain)
            .navigationTitle("Warranties")
            .searchable(text: $searchText, prompt: "Search warranties")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddWarrantyView()
            }
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(WarrantyItem.ProductCategory.allCases, id: \.self) { cat in
                    FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - WarrantyDetailView

struct WarrantyDetailView: View {
    let item: WarrantyItem
    
    var body: some View {
        List {
            Section("Product") {
                LabeledContent("Name", value: item.productName)
                LabeledContent("Store", value: item.storeName)
                LabeledContent("Price", value: item.price.formatted(.currency(code: "EUR")))
                LabeledContent("Category", value: item.category.rawValue)
            }
            
            Section("Warranty") {
                LabeledContent("Purchased", value: item.purchaseDate.formatted(date: .long, time: .omitted))
                LabeledContent("Expires", value: item.warrantyExpiry.formatted(date: .long, time: .omitted))
                LabeledContent("Days Remaining") {
                    Text("\(item.daysRemaining) days")
                        .foregroundStyle(item.statusColor)
                        .fontWeight(.semibold)
                }
            }
            
            if item.documentURL != nil {
                Section("Documents") {
                    Label("View Receipt", systemImage: "doc.fill")
                    Label("View Manual", systemImage: "book.fill")
                }
            }
        }
        .navigationTitle(item.productName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AddWarrantyView (Placeholder)

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
                Section("Product Details") {
                    TextField("Product name", text: $productName)
                    TextField("Store", text: $storeName)
                    TextField("Price (€)", text: $price)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(WarrantyItem.ProductCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section("Warranty") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    Stepper("Warranty: \(warrantyYears) year\(warrantyYears > 1 ? "s" : "")",
                            value: $warrantyYears, in: 1...10)
                }
                
                Section {
                    // TODO: Document / receipt scanning via VisionKit
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
}
