import SwiftUI

struct AddAssetView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var name = ""
    @State private var brand = ""
    @State private var modelName = ""
    @State private var serialNumber = ""
    @State private var selectedCategory: Asset.AssetCategory = .other
    @State private var purchaseDate = Date()
    @State private var purchasePrice: Double = 0
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Product Info
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
                
                // Purchase
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
                
                // Notes
                Section("Notes") {
                    TextField("Additional notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAsset()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveAsset() {
        let asset = Asset(
            name: name.trimmingCharacters(in: .whitespaces),
            category: selectedCategory,
            brand: brand.trimmingCharacters(in: .whitespaces),
            modelName: modelName.trimmingCharacters(in: .whitespaces),
            serialNumber: serialNumber.trimmingCharacters(in: .whitespaces),
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        store.addAsset(asset)
        dismiss()
    }
}

#Preview {
    AddAssetView()
        .environmentObject(DomoStore())
}
