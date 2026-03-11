import SwiftUI

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    
    @State private var showMenu = false
    
    // Sheet states
    @State private var showAddWarranty = false
    @State private var showAddSubscription = false
    @State private var showAddMaintenance = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrim
            if showMenu {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
            } else {
                Color.clear
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 14) {
                // Action menu
                if showMenu {
                    VStack(spacing: 0) {
                        menuItem(icon: "shield.lefthalf.filled", label: "Add Warranty", color: .green) {
                            close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showAddWarranty = true }
                        }
                        Divider().padding(.leading, 48)
                        menuItem(icon: "arrow.triangle.2.circlepath", label: "Add Subscription", color: .blue) {
                            close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showAddSubscription = true }
                        }
                        Divider().padding(.leading, 48)
                        menuItem(icon: "wrench.and.screwdriver", label: "Add Task", color: .orange) {
                            close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showAddMaintenance = true }
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    .frame(maxWidth: 240)
                    .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                }
                
                // FAB pill
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showMenu.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .rotationEffect(.degrees(showMenu ? 45 : 0))
                        if !showMenu {
                            Text("Add")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, showMenu ? 16 : 20)
                    .padding(.vertical, 12)
                    .background(.blue.gradient, in: Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 56)
        }
        .sheet(isPresented: $showAddWarranty) {
            AddWarrantyView()
        }
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionView()
        }
        .sheet(isPresented: $showAddMaintenance) {
            AddMaintenanceTaskView()
        }
    }
    
    // MARK: - Menu Item
    
    private func menuItem(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func close() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            showMenu = false
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FloatingActionButton()
    }
}
