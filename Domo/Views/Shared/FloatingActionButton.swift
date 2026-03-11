import SwiftUI

// MARK: - Floating Action Button

/// Compact "+" pill anchored bottom-leading. Tapping presents the QuickAddSheet.
struct FloatingActionButton: View {

    @State private var showSheet = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    showSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                        Text("Add")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.blue.gradient, in: Capsule())
                    .shadow(color: .blue.opacity(0.25), radius: 10, y: 4)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.leading, 20)
            .padding(.bottom, 56)
        }
        .allowsHitTesting(true)     // only the pill intercepts taps
        .sheet(isPresented: $showSheet) {
            QuickAddSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FloatingActionButton()
    }
    .environmentObject(DomoStore())
}
