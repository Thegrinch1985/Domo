import SwiftUI

/// Shows a monthly cost breakdown: subscriptions, insurance, maintenance.
struct LifeOverheadCard: View {

    @EnvironmentObject private var store: DomoStore

    private var subscriptionCost: Double {
        store.subscriptions.filter(\.isActive).reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private var insuranceCost: Double {
        // premium is yearly; convert to monthly
        store.insurancePolicies.reduce(0) { $0 + (($1.premium ?? 0) / 12.0) }
    }

    private var maintenanceCost: Double {
        // estimatedCost per interval → monthly
        store.maintenanceTasks.reduce(0) { total, task in
            guard task.intervalMonths > 0, task.estimatedCost > 0 else { return total }
            return total + (task.estimatedCost / Double(task.intervalMonths))
        }
    }

    private var totalMonthly: Double {
        subscriptionCost + insuranceCost + maintenanceCost
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top: prominent total
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Life Overhead")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.7))
                
                Text(totalMonthly.formatted(.currency(code: "EUR")))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                Text("per month")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 28)
            .padding(.bottom, 22)
            
            // Bottom: breakdown rows
            VStack(spacing: 10) {
                costRow(icon: "arrow.triangle.2.circlepath", label: "Subscriptions", amount: subscriptionCost)
                costRow(icon: "shield.checkered", label: "Insurance", amount: insuranceCost)
                costRow(icon: "wrench.and.screwdriver", label: "Maintenance est.", amount: maintenanceCost)
            }
            .padding(16)
            .background(.white.opacity(0.08))
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.indigo, .purple.opacity(0.85), .blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusLarge))
        .shadow(color: .indigo.opacity(0.35), radius: 20, y: 10)
    }

    private func costRow(icon: String, label: String, amount: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(amount.formatted(.currency(code: "EUR")))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    LifeOverheadCard()
        .padding()
        .environmentObject(DomoStore())
}
