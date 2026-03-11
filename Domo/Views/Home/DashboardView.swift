import SwiftUI

struct DashboardView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: DomoTheme.sectionSpacing) {
            
            // Warranties expiring soon
            dashboardSection(
                title: "Warranties Expiring",
                icon: "shield.lefthalf.filled",
                iconGradient: DomoTheme.warmGradient,
                isEmpty: expiringWarranties.isEmpty,
                emptyText: "No warranties expiring soon"
            ) {
                appState.selectedTab = .documents
            } content: {
                ForEach(expiringWarranties) { item in
                    warrantyCard(item)
                }
            }
            
            // Subscription renewals
            dashboardSection(
                title: "Upcoming Renewals",
                icon: "arrow.triangle.2.circlepath",
                iconGradient: DomoTheme.brandGradient,
                isEmpty: upcomingRenewals.isEmpty,
                emptyText: "No upcoming renewals"
            ) {
                appState.selectedTab = .subscriptions
            } content: {
                ForEach(upcomingRenewals) { sub in
                    subscriptionCard(sub)
                }
            }
            
            // Maintenance tasks due
            dashboardSection(
                title: "Maintenance Due",
                icon: "wrench.and.screwdriver",
                iconGradient: DomoTheme.successGradient,
                isEmpty: upcomingMaintenance.isEmpty,
                emptyText: "No tasks due soon"
            ) {
                // Currently maintenance lives on Home; this scrolls to top
            } content: {
                ForEach(upcomingMaintenance) { task in
                    maintenanceCard(task)
                }
            }
        }
    }
    
    // MARK: - Data
    
    private var expiringWarranties: [WarrantyItem] {
        store.warranties
            .filter { !$0.isExpired }
            .sorted { $0.daysRemaining < $1.daysRemaining }
            .prefix(3)
            .map { $0 }
    }
    
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
        iconGradient: LinearGradient,
        isEmpty: Bool,
        emptyText: String,
        onSeeAll: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
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
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
            } else {
                VStack(spacing: 8) {
                    content()
                }
            }
        }
    }
    
    // MARK: - Warranty Card
    
    private func warrantyCard(_ item: WarrantyItem) -> some View {
        HStack(spacing: 14) {
            // Status dot
            Circle()
                .fill(item.statusColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.productName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                
                Text("Expires \(item.warrantyExpiry.formatted(.dateTime.month().day().year()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Countdown
            Text("\(item.daysRemaining)d")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(item.isExpiringSoon ? .orange : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (item.isExpiringSoon ? Color.orange : Color.blue).opacity(0.1)
                )
                .clipShape(Capsule())
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(item.isExpiringSoon ? .orange.opacity(0.2) : .clear, lineWidth: 1)
        )
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
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
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
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
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
