import SwiftUI

struct AddAssetView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    // Pre-filled from scanner
    let barcode: String
    
    @State private var name = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var purchaseDate = Date()
    @State private var warrantyMonths: Int = 12
    @State private var notes = ""
    
    @State private var showScanner = false
    @State private var currentBarcode: String
    
    init(barcode: String = "") {
        self.barcode = barcode
        _currentBarcode = State(initialValue: barcode)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Barcode section
                Section("Barcode") {
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundStyle(.secondary)
                        Text(currentBarcode.isEmpty ? "No barcode" : currentBarcode)
                            .foregroundStyle(currentBarcode.isEmpty ? .secondary : .primary)
                            .monospaced()
                        Spacer()
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 20))
                        }
                    }
                }
                
                // Product Info
                Section("Product Information") {
                    TextField("Name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                }
                
                // Purchase & Warranty
                Section("Purchase & Warranty") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    Stepper(value: $warrantyMonths, in: 0...120) {
                        HStack {
                            Text("Warranty")
                            Spacer()
                            Text("\(warrantyMonths) month\(warrantyMonths == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }
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
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView()
            }
        }
    }
    
    private func saveAsset() {
        let asset = Asset(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            barcode: currentBarcode,
            purchaseDate: purchaseDate,
            warrantyMonths: warrantyMonths,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        store.addAsset(asset)
        dismiss()
    }
}

#Preview {
    AddAssetView(barcode: "5901234123457")
        .environmentObject(DomoStore())
}
