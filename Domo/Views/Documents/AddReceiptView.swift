import SwiftUI
import PhotosUI

struct AddReceiptView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var title = ""
    @State private var category: Receipt.ReceiptCategory = .general
    @State private var purchaseDate = Date()
    @State private var warrantyMonths: Int = 12
    @State private var receiptImageData: Data?
    
    // Image picker state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSourceMenu = false
    @State private var showCamera = false
    
    private var previewImage: UIImage? {
        guard let data = receiptImageData else { return nil }
        return UIImage(data: data)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Receipt image
                Section {
                    imageSection
                }
                
                // Details
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $category) {
                        ForEach(Receipt.ReceiptCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    
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
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveReceipt() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Add Receipt Photo", isPresented: $showSourceMenu) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") {} // handled by PhotosPicker below
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker(imageData: $receiptImageData)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        receiptImageData = data
                    }
                }
            }
        }
    }
    
    // MARK: - Image Section
    
    @ViewBuilder
    private var imageSection: some View {
        if let image = previewImage {
            VStack(spacing: 12) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                HStack(spacing: 16) {
                    Button(role: .destructive) {
                        withAnimation { receiptImageData = nil; selectedPhoto = nil }
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    photoPickerButton(label: "Replace")
                }
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        } else {
            VStack(spacing: 16) {
                Image(systemName: "receipt")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                
                Text("No receipt image")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    photoPickerButton(label: "Library")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
    }
    
    private func photoPickerButton(label: String) -> some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images
        ) {
            Label(label, systemImage: "photo.on.rectangle")
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.bordered)
    }
    
    // MARK: - Save
    
    private func saveReceipt() {
        let receipt = Receipt(
            title: title.trimmingCharacters(in: .whitespaces),
            category: category,
            purchaseDate: purchaseDate,
            warrantyMonths: warrantyMonths,
            receiptImage: receiptImageData
        )
        store.addReceipt(receipt)
        dismiss()
    }
}

// MARK: - Camera Image Picker (UIImagePickerController wrapper)

private struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }
        
        nonisolated func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            let data = image?.jpegData(compressionQuality: 0.8)
            Task { @MainActor in
                self.parent.imageData = data
                self.parent.dismiss()
            }
        }
        
        nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in
                self.parent.dismiss()
            }
        }
    }
}

#Preview {
    AddReceiptView()
        .environmentObject(DomoStore())
}
