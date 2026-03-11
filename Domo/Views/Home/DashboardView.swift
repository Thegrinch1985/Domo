import SwiftUI

struct DashboardView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: DomoTheme.sectionSpacing) {
            
            // Hero: Life Overhead
            LifeOverheadCard()
            
            // Upcoming Renewals
            dashboardSection(
                title: "Upcoming Renewals",
                icon: "arrow.triangle.2.circlepath",
                isEmpty: upcomingRenewals.isEmpty,
                emptyText: "No upcoming renewals"
            ) {
                appState.selectedTab = .subscriptions
            } content: {
                ForEach(upcomingRenewals) { sub in
                    subscriptionCard(sub)
                }
            }
            
            // Maintenance Due
            dashboardSection(
                title: "Maintenance Due",
                icon: "wrench.and.screwdriver",
                isEmpty: upcomingMaintenance.isEmpty,
                emptyText: "No tasks due soon"
            ) {
                // no-op
            } content: {
                ForEach(upcomingMaintenance) { task in
                    maintenanceCard(task)
                }
            }
        }
    }
    
    // MARK: - Data
    
    private var upcomingRenewals: [Subscription] {
        store.subscriptions
            .filter(\.isActive)
            .sorted { $0.daysUntilRenewal < $1.daysUntilRenewal }
            .prefix(3)
            .map { $0 }
    }
    
    private var upcomingMaintenance: [MaintenanceTask] {
        store.maintenanceTasks
            .filter { $0.nextDueDate != nil }
            .sorted {
                ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture)
            }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Section Builder
    
    private func dashboardSection<Content: View>(
        title: String,
        icon: String,
        isEmpty: Bool,
        emptyText: String,
        onSeeAll: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    onSeeAll()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            if isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DomoTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium, style: .continuous))
                .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
            } else {
                VStack(spacing: 8) {
                    content()
                }
            }
        }
    }
    
    // MARK: - Subscription Card
    
    private func subscriptionCard(_ sub: Subscription) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: sub.colorHex).gradient)
                    .frame(width: 38, height: 38)
                Image(systemName: sub.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(sub.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                
                Text("Renews \(sub.renewalDate.formatted(.dateTime.month().day()))")
                    .font(.caption)
                    .foregroundStyle(sub.daysUntilRenewal <= 3 ? .orange : .secondary)
            }
            
            Spacer()
            
            Text(sub.price.formatted(.currency(code: "EUR")))
                .font(.subheadline.bold())
        }
        .domoRow()
    }
    
    // MARK: - Maintenance Card
    
    private func maintenanceCard(_ task: MaintenanceTask) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(task.isOverdue ? .red : task.isDueSoon ? .orange : .green)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                
                if let due = task.nextDueDate {
                    Text(task.isOverdue ? "Overdue" : "Due \(due.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
            if let due = task.nextDueDate {
                Text(due, style: .relative)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(task.isOverdue ? .red : task.isDueSoon ? .orange : .secondary)
            }
        }
        .domoRow()
    }
}

#Preview {
    ScrollView {
        DashboardView()
            .padding(.horizontal, 20)
    }
    .environmentObject(AppState())
    .environmentObject(DomoStore())
}
