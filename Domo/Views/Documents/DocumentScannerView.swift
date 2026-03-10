import SwiftUI
import SwiftData
import VisionKit

// MARK: - DocumentScannerView

struct DocumentScannerView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scannedImages: [UIImage] = []
    @State private var isShowingScanner = false
    @State private var title = ""
    @State private var category = "Receipt"
    @State private var selectedPage = 0

    private let categories = ["Receipt", "Invoice", "Contract", "Manual", "Other"]

    var body: some View {
        NavigationStack {
            Group {
                if scannedImages.isEmpty {
                    scanPrompt
                } else {
                    scannedContent
                }
            }
            .navigationTitle("Scan Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !scannedImages.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .disabled(title.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                DocumentCameraRepresentable { images in
                    scannedImages = images
                }
            }
        }
    }

    // MARK: - Subviews

    private var scanPrompt: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(.blue)
            Text("Scan a receipt or document")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button {
                isShowingScanner = true
            } label: {
                Label("Scan Document", systemImage: "camera.viewfinder")
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

    private var scannedContent: some View {
        Form {
            Section("Preview") {
                TabView(selection: $selectedPage) {
                    ForEach(scannedImages.indices, id: \.self) { index in
                        Image(uiImage: scannedImages[index])
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: scannedImages.count > 1 ? .always : .never))
                .frame(height: 320)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Details") {
                TextField("Title", text: $title)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
            }

            Section {
                Text("\(scannedImages.count) page\(scannedImages.count == 1 ? "" : "s") scanned")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Rescan") {
                    scannedImages = []
                    isShowingScanner = true
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        for (index, image) in scannedImages.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.85) else { continue }
            let pageTitle = scannedImages.count == 1
                ? title
                : "\(title) (page \(index + 1))"
            let document = Document(
                title: pageTitle,
                category: category,
                imageData: data
            )
            modelContext.insert(document)
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - UIViewControllerRepresentable Wrapper

struct DocumentCameraRepresentable: UIViewControllerRepresentable {

    let onScan: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    // MARK: - Coordinator

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([UIImage]) -> Void

        init(onScan: @escaping ([UIImage]) -> Void) {
            self.onScan = onScan
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            onScan(images)
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("Document scan failed: \(error.localizedDescription)")
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentScannerView()
        .modelContainer(for: Document.self, inMemory: true)
}
