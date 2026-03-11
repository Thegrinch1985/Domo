import SwiftUI

// MARK: - Quick Add Action

enum QuickAddAction: String, Identifiable, CaseIterable {
    case scanDocument
    case addAsset
    case addSubscription
    case addWarranty
    case addMaintenance
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .scanDocument:    return "Scan Document"
        case .addAsset:        return "Add Asset"
        case .addSubscription: return "Add Subscription"
        case .addWarranty:     return "Add Warranty"
        case .addMaintenance:  return "Add Maintenance Task"
        }
    }
    
    var icon: String {
        switch self {
        case .scanDocument:    return "doc.viewfinder"
        case .addAsset:        return "barcode.viewfinder"
        case .addSubscription: return "arrow.triangle.2.circlepath"
        case .addWarranty:     return "shield.lefthalf.filled"
        case .addMaintenance:  return "wrench.and.screwdriver"
        }
    }
    
    var color: Color {
        switch self {
        case .scanDocument:    return .blue
        case .addAsset:        return .indigo
        case .addSubscription: return .purple
        case .addWarranty:     return .green
        case .addMaintenance:  return .orange
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    
    @State private var showMenu = false
    @State private var selectedAction: QuickAddAction?
    
    // Individual sheet states
    @State private var showScanner = false
    @State private var showAddAsset = false
    @State private var showAddSubscription = false
    @State private var showAddWarranty = false
    @State private var showAddMaintenance = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background scrim
            if showMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
            }
            
            VStack(alignment: .trailing, spacing: 12) {
                // Action items
                if showMenu {
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(Array(QuickAddAction.allCases.enumerated()), id: \.element.id) { index, action in
                            menuRow(action: action)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .bottom)
                                            .combined(with: .opacity)
                                            .animation(.spring(response: 0.35, dampingFraction: 0.75).delay(Double(index) * 0.04)),
                                        removal: .opacity.animation(.easeOut(duration: 0.15))
                                    )
                                )
                        }
                    }
                }
                
                // FAB button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showMenu.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: .blue.opacity(0.35), radius: 12, y: 6)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(showMenu ? 45 : 0))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        // Sheets
        .fullScreenCover(isPresented: $showScanner) {
            BarcodeScannerView()
        }
        .sheet(isPresented: $showAddAsset) {
            AddAssetView()
        }
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionView()
        }
        .sheet(isPresented: $showAddWarranty) {
            AddWarrantyView()
        }
        .sheet(isPresented: $showAddMaintenance) {
            AddMaintenanceTaskView()
        }
    }
    
    // MARK: - Menu Row
    
    private func menuRow(action: QuickAddAction) -> some View {
        Button {
            close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                trigger(action)
            }
        } label: {
            HStack(spacing: 12) {
                Text(action.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                ZStack {
                    Circle()
                        .fill(action.color.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: action.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showMenu = false
        }
    }
    
    private func trigger(_ action: QuickAddAction) {
        switch action {
        case .scanDocument:    showScanner = true
        case .addAsset:        showAddAsset = true
        case .addSubscription: showAddSubscription = true
        case .addWarranty:     showAddWarranty = true
        case .addMaintenance:  showAddMaintenance = true
        }
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        FloatingActionButton()
    }
}
