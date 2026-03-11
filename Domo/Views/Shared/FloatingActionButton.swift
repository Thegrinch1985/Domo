import SwiftUI

// MARK: - Floating Action Button

/// Compact "+" circle anchored bottom-trailing on every tab.
struct FloatingActionButton: View {

    @State private var showSheet = false
    @State private var pressed = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(.blue.gradient, in: Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 12, y: 5)
                        .scaleEffect(pressed ? 0.9 : 1)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: showSheet)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in withAnimation(.easeOut(duration: 0.1)) { pressed = true } }
                        .onEnded { _ in withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pressed = false } }
                )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 56)
        }
        .allowsHitTesting(true)
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
