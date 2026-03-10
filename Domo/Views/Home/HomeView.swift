import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    @State private var showProfile = false
    @State private var showAddTask = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DomoTheme.sectionSpacing) {
                    
                    // Hero greeting
                    greetingHeader
                    
                    // Urgent alerts
                    if !store.urgentAlerts.isEmpty {
                        AlertBanner(alerts: store.urgentAlerts)
                    }
                    
                    // Quick stats
                    statsRow
                    
                    // Quick actions grid
                    quickActions
                    
                    // Maintenance section
                    maintenanceSection
                    
                    // Recent warranties
                    warrantiesSection
                }
                .padding(.horizontal, DomoTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Domo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            // TODO: Open scan sheet
                        } label: {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            showProfile = true
                        } label: {
                            ProfileAvatar(initials: appState.profileInitials, size: 32)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileSheet()
            }
            .sheet(isPresented: $showAddTask) {
                AddMaintenanceTaskView()
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
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Quick Actions")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionButton(icon: "doc.viewfinder", label: "Scan", gradient: DomoTheme.brandGradient) {
                    // TODO
                }
                QuickActionButton(icon: "plus.circle.fill", label: "Warranty", gradient: DomoTheme.successGradient) {
                    appState.selectedTab = .documents
                }
                QuickActionButton(icon: "car.fill", label: "Service", gradient: .linearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                    appState.selectedTab = .car
                }
                QuickActionButton(icon: "shield.fill", label: "Insurance", gradient: DomoTheme.warmGradient) {
                    appState.selectedTab = .vault
                }
            }
        }
    }
    
    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Maintenance", action: store.maintenanceTasks.isEmpty ? "Add Task" : "See all") {
                showAddTask = true
            }
            
            if store.maintenanceTasks.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                    Text("No maintenance tasks yet. Add one to stay on top of home upkeep.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DomoTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
            } else {
                VStack(spacing: 8) {
                    ForEach(store.maintenanceTasks.prefix(3)) { task in
                        MaintenanceRow(task: task) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                store.markTaskComplete(task)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var warrantiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Warranties", action: "See all") {
                appState.selectedTab = .documents
            }
            
            VStack(spacing: 8) {
                ForEach(store.warranties.prefix(3)) { item in
                    WarrantyRow(item: item)
                }
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

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(gradient)
                }
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
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
                .strokeBorder(.white.opacity(0.04), lineWidth: 1)
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
            notes: notes.isEmpty ? nil : notes
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
