import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Greeting
                    greetingHeader
                    
                    // Urgent alerts
                    if !store.urgentAlerts.isEmpty {
                        AlertBanner(alerts: store.urgentAlerts)
                    }
                    
                    // Stats row
                    statsRow
                    
                    // Maintenance section
                    maintenanceSection
                    
                    // Recent warranties
                    warrantiesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Domo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: Open scan sheet
                    } label: {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 20, weight: .medium))
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(appState.userName)
                .font(.title.bold())
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 14) {
            StatCard(
                title: "Monthly",
                value: store.totalMonthlySpend.formatted(.currency(code: "EUR")),
                subtitle: "\(store.subscriptions.filter(\.isActive).count) subscriptions",
                icon: "creditcard.fill",
                tint: .blue
            ) {
                appState.selectedTab = .subscriptions
            }
            
            StatCard(
                title: "Warranties",
                value: "\(store.warranties.count)",
                subtitle: "\(store.warranties.filter(\.isExpiringSoon).count) expiring soon",
                icon: "shield.fill",
                tint: store.warranties.filter(\.isExpiringSoon).isEmpty ? .green : .orange
            ) {
                appState.selectedTab = .documents
            }
        }
    }
    
    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Maintenance", action: "See all") {
                // TODO: Navigate to full maintenance list
            }
            
            ForEach(store.maintenanceTasks.prefix(3)) { task in
                MaintenanceRow(task: task) {
                    store.markTaskComplete(task)
                }
            }
        }
    }
    
    private var warrantiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Warranties", action: "See all") {
                appState.selectedTab = .documents
            }
            
            ForEach(store.warranties.prefix(3)) { item in
                WarrantyRow(item: item)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }
}

// MARK: - Supporting Views

private struct AlertBanner: View {
    let alerts: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Action Required", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.bold())
                .foregroundStyle(.orange)
            
            Text(alerts.first ?? "")
                .font(.subheadline.weight(.medium))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MaintenanceRow: View {
    let task: MaintenanceTask
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                if let due = task.nextDueDate {
                    Text(due, style: .relative)
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
            }
            Spacer()
            Button("Done") { onComplete() }
                .font(.caption.bold())
                .foregroundStyle(.blue)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(14)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(DomoStore())
}
