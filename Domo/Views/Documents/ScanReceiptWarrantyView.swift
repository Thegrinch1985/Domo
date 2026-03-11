import SwiftUI
import VisionKit

/// Scan a receipt with the camera, then fill in warranty details and save.
struct ScanReceiptWarrantyView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore

    // Scanner state
    @State private var scannedImage: UIImage?
    @State private var isShowingScanner = true

    // Warranty form
    @State private var productName = ""
    @State private var storeName = ""
    @State private var purchaseDate = Date()
    @State private var purchasePrice = ""
    @State private var warrantyMonths = 12
    @State private var category: WarrantyItem.ProductCategory = .electronics

    private var expiryDate: Date {
        Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) ?? purchaseDate
    }

    var body: some View {
        NavigationStack {
            Group {
                if scannedImage == nil {
                    scanPrompt
                } else {
                    warrantyForm
                }
            }
            .navigationTitle(scannedImage == nil ? "Scan Receipt" : "New Warranty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if scannedImage != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .fontWeight(.semibold)
                            .disabled(productName.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                DocumentCameraRepresentable { images in
                    scannedImage = images.first
                }
            }
        }
    }

    // MARK: - Scan Prompt

    private var scanPrompt: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "receipt")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(.blue)
            Text("Scan a receipt to create a warranty")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button {
                isShowingScanner = true
            } label: {
                Label("Open Camera", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Warranty Form

    private var warrantyForm: some View {
        Form {
            // Receipt preview
            Section("Receipt") {
                if let image = scannedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxHeight: 220)
                        .frame(maxWidth: .infinity)
                }
                Button("Rescan") {
                    scannedImage = nil
                    isShowingScanner = true
                }
            }

            // Product details
            Section("Product Details") {
                TextField("Product name", text: $productName)
                TextField("Store", text: $storeName)
                TextField("Price (€)", text: $purchasePrice)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: $category) {
                    ForEach(WarrantyItem.ProductCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
            }

            // Warranty period
            Section("Warranty") {
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                Stepper("Warranty: \(warrantyMonths) month\(warrantyMonths == 1 ? "" : "s")",
                        value: $warrantyMonths, in: 1...120)

                HStack {
                    Text("Expires")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(expiryDate.formatted(date: .long, time: .omitted))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        let imageData = scannedImage?.jpegData(compressionQuality: 0.85)

        // Convert months to whole years (round up) for WarrantyItem's year-based model
        let years = max(1, Int(ceil(Double(warrantyMonths) / 12.0)))

        let item = WarrantyItem(
            productName: productName,
            storeName: storeName,
            purchaseDate: purchaseDate,
            warrantyYears: years,
            price: Double(purchasePrice) ?? 0,
            category: category,
            receiptImageData: imageData
        )
        store.addWarranty(item)
        dismiss()
    }
}

#Preview {
    ScanReceiptWarrantyView()
        .environmentObject(DomoStore())
}
