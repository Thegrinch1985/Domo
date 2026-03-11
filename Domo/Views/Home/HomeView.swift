import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    @State private var showProfile = false
    @State private var showSearch = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Greeting
                    greetingHeader
                    
                    // Urgent alerts
                    if !store.urgentAlerts.isEmpty {
                        AlertBanner(alerts: store.urgentAlerts)
                    }
                    
                    // Quick stats
                    statsRow
                    
                    // Dashboard: upcoming items
                    DashboardView()
                }
                .padding(.horizontal, DomoTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        ProfileAvatar(initials: appState.profileInitials, size: 32)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileSheet()
            }
            .sheet(isPresented: $showSearch) {
                GlobalSearchView()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(appState.userName)
                .font(.title.bold())
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: DomoTheme.itemSpacing) {
            StatCard(
                title: "Monthly",
                value: store.totalMonthlySpend.formatted(.currency(code: "EUR")),
                subtitle: "\(store.subscriptions.filter(\.isActive).count) subscriptions",
                icon: "creditcard.fill",
                gradient: DomoTheme.brandGradient
            ) {
                appState.selectedTab = .subscriptions
            }
            
            StatCard(
                title: "Warranties",
                value: "\(store.warranties.count)",
                subtitle: "\(store.warranties.filter(\.isExpiringSoon).count) expiring soon",
                icon: "shield.lefthalf.filled",
                gradient: store.warranties.contains(where: \.isExpiringSoon)
                    ? DomoTheme.warmGradient
                    : DomoTheme.successGradient
            ) {
                appState.selectedTab = .documents
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

// MARK: - Alert Banner

private struct AlertBanner: View {
    let alerts: [String]
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("Action Required")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Spacer()
                if alerts.count > 1 {
                    Text("\(currentIndex + 1)/\(alerts.count)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange.opacity(0.7))
                }
            }
            
            Text(alerts[currentIndex])
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .contentTransition(.numericText())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(.orange.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            if alerts.count > 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentIndex = (currentIndex + 1) % alerts.count
                }
            }
        }
    }
}

// MARK: - Maintenance Row

private struct MaintenanceRow: View {
    let task: MaintenanceTask
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            Circle()
                .fill(task.isOverdue ? .red : task.isDueSoon ? .orange : .green)
                .frame(width: 8, height: 8)
            
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
            Button {
                onComplete()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Profile Sheet

struct ProfileSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        ProfileAvatar(initials: appState.profileInitials, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.userName)
                                .font(.title3.bold())
                            Text(appState.userEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Preferences") {
                    Label("Notifications", systemImage: "bell.badge.fill")
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label("Appearance", systemImage: "paintbrush.fill")
                    }
                    Label("Currency", systemImage: "eurosign.circle.fill")
                }
                
                Section("Data") {
                    Label("Export Data", systemImage: "square.and.arrow.up.fill")
                    Label("Backup & Sync", systemImage: "icloud.fill")
                }
                
                Section {
                    Button(role: .destructive) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            appState.signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Maintenance Task

struct AddMaintenanceTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var title = ""
    @State private var intervalMonths = 6
    @State private var hasBeenDone = false
    @State private var lastCompleted = Date()
    @State private var notes = ""
    @State private var enableReminder = true
    @State private var reminderDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task name (e.g. Boiler Service)", text: $title)
                    Stepper("Every \(intervalMonths) month\(intervalMonths > 1 ? "s" : "")",
                            value: $intervalMonths, in: 1...24)
                }
                Section("History") {
                    Toggle("Previously completed", isOn: $hasBeenDone)
                    if hasBeenDone {
                        DatePicker("Last completed", selection: $lastCompleted, displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Reminder") {
                    Toggle("Remind me when due", isOn: $enableReminder)
                    if enableReminder {
                        DatePicker("Reminder date", selection: $reminderDate, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let task = MaintenanceTask(
            title: title,
            intervalMonths: intervalMonths,
            lastCompleted: hasBeenDone ? lastCompleted : nil,
            notes: notes.isEmpty ? nil : notes,
            reminderDate: enableReminder ? reminderDate : nil
        )
        store.addTask(task)
        dismiss()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(DomoStore())
        .preferredColorScheme(.dark)
}
