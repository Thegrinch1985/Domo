import SwiftUI
import AVFoundation

// MARK: - Public SwiftUI View

struct BarcodeScannerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var showAddAsset = false
    @State private var torchOn = false
    @State private var cameraAuthorized = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if cameraAuthorized {
                    CameraPreviewRepresentable(
                        scannedCode: $scannedCode,
                        torchOn: $torchOn
                    )
                    .ignoresSafeArea()
                    
                    scanOverlay
                } else {
                    cameraPermissionView
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        torchOn.toggle()
                    } label: {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .onChange(of: scannedCode) { _, code in
                guard let code, !code.isEmpty else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showAddAsset = true
            }
            .sheet(isPresented: $showAddAsset, onDismiss: {
                // Reset so the scanner can fire again
                scannedCode = nil
            }) {
                AddAssetView()
            }
            .onAppear(perform: checkCameraAuth)
        }
    }
    
    // MARK: - Camera Permission
    
    private func checkCameraAuth() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { cameraAuthorized = granted }
            }
        default:
            cameraAuthorized = false
        }
    }
    
    private var cameraPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Camera Access Required")
                .font(.title3.bold())
            Text("Open Settings to allow camera access for barcode scanning.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Scan Overlay
    
    private var scanOverlay: some View {
        ZStack {
            // Dimmed surround
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .reverseMask {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: 260, height: 260)
                }
            
            // Frame lines
            scanFrame
            
            // Instruction
            VStack {
                Spacer()
                Text("Align barcode inside the frame")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 60)
            }
        }
        .allowsHitTesting(false)
    }
    
    private var scanFrame: some View {
        let size: CGFloat = 260
        let cornerLength: CGFloat = 36
        let lineWidth: CGFloat = 4
        
        return ZStack {
            // Top-left
            CornerShape(corner: .topLeft, length: cornerLength)
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            // Top-right
            CornerShape(corner: .topRight, length: cornerLength)
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            // Bottom-left
            CornerShape(corner: .bottomLeft, length: cornerLength)
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            // Bottom-right
            CornerShape(corner: .bottomRight, length: cornerLength)
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Corner Shape

private struct CornerShape: Shape {
    enum Corner { case topLeft, topRight, bottomLeft, bottomRight }
    let corner: Corner
    let length: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch corner {
        case .topLeft:
            p.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        case .topRight:
            p.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        case .bottomLeft:
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY - length))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        case .bottomRight:
            p.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        }
        return p
    }
}

// MARK: - Reverse Mask Helper

private extension View {
    @ViewBuilder
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

private struct CameraPreviewRepresentable: UIViewRepresentable {
    @Binding var scannedCode: String?
    @Binding var torchOn: Bool
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.setTorch(torchOn)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }
    
    final class Coordinator: NSObject, ScannerDelegate {
        @Binding var scannedCode: String?
        init(scannedCode: Binding<String?>) { _scannedCode = scannedCode }
        
        func didFind(code: String) {
            guard scannedCode == nil else { return }
            DispatchQueue.main.async { self.scannedCode = code }
        }
    }
}

// MARK: - Scanner Delegate Protocol

@MainActor
private protocol ScannerDelegate: AnyObject {
    func didFind(code: String)
}

// MARK: - Camera Preview UIView

private final class CameraPreviewUIView: UIView, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: ScannerDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSession()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    private func setupSession() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera)
        else { return }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [
                .ean8, .ean13, .upce, .code128, .code39, .code93,
                .pdf417, .qr, .dataMatrix, .aztec, .itf14
            ]
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue
        else { return }
        
        Task { @MainActor [weak self] in
            self?.delegate?.didFind(code: value)
        }
    }
    
    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch
        else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

#Preview {
    BarcodeScannerView()
}
