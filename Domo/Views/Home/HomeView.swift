import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    @State private var showProfile = false
    @State private var showSearch = false
    @State private var showGreeting = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Greeting — pops in then auto-hides
                    if showGreeting {
                        greetingHeader
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Urgent alerts
                    if !store.urgentAlerts.isEmpty {
                        AlertBanner(alerts: store.urgentAlerts)
                    }
                    
                    // Dashboard: upcoming items
                    DashboardView()
                }
                .padding(.horizontal, DomoTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Domo")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showGreeting = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showGreeting = false
                    }
                }
            }
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
                        ProfileAvatar(initials: appState.profileInitials, size: 32, imageData: appState.profileImageData)
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
        .background(.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium, style: .continuous))
        .shadow(color: .orange.opacity(0.08), radius: 8, y: 2)
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
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium, style: .continuous))
        .shadow(color: DomoTheme.cardShadowColor, radius: DomoTheme.cardShadowRadius, y: DomoTheme.cardShadowY)
    }
}

// MARK: - Profile Sheet

struct ProfileSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: DomoStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showImagePicker = false
    @State private var showExportShare = false
    @State private var exportURL: URL?
    @State private var showBackupAlert = false
    @State private var backupMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Profile header with avatar picker
                Section {
                    VStack(spacing: 16) {
                        // Tappable avatar
                        Button {
                            showImagePicker = true
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                ProfileAvatar(
                                    initials: appState.profileInitials,
                                    size: 80,
                                    imageData: appState.profileImageData
                                )
                                
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue)
                                    .offset(x: 4, y: 4)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        VStack(spacing: 4) {
                            Text(appState.userName)
                                .font(.title3.bold())
                            Text(appState.userEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }
                
                // Notifications
                Section("Notifications") {
                    Toggle(isOn: $appState.notificationsEnabled) {
                        Label("Push Notifications", systemImage: "bell.badge.fill")
                    }
                    .onChange(of: appState.notificationsEnabled) { _, enabled in
                        if enabled {
                            Task {
                                let granted = await NotificationService.shared.requestPermission()
                                if !granted {
                                    appState.notificationsEnabled = false
                                }
                            }
                        }
                    }
                }
                
                // Preferences
                Section("Preferences") {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label("Appearance", systemImage: "paintbrush.fill")
                    }
                    
                    Picker(selection: $appState.currencyCode) {
                        ForEach(AppState.supportedCurrencies, id: \.self) { code in
                            Text(currencyLabel(for: code)).tag(code)
                        }
                    } label: {
                        Label("Currency", systemImage: "banknote.fill")
                    }
                }
                
                // Data
                Section("Data") {
                    Button {
                        exportData()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up.fill")
                            .foregroundStyle(.primary)
                    }
                    
                    Button {
                        backupData()
                    } label: {
                        Label("Backup to Files", systemImage: "icloud.and.arrow.up.fill")
                            .foregroundStyle(.primary)
                    }
                }
                
                // Sign out
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
                
                // App version
                Section {
                    HStack {
                        Spacer()
                        Text("Domo v1.0")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker { image in
                    if let data = image.jpegData(compressionQuality: 0.7) {
                        appState.profileImageData = data
                    }
                }
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Backup", isPresented: $showBackupAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(backupMessage)
            }
        }
    }
    
    // MARK: - Currency Label
    
    private func currencyLabel(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        let symbol = formatter.currencySymbol ?? code
        return "\(code) (\(symbol))"
    }
    
    // MARK: - Export
    
    private func exportData() {
        let data = buildExportPayload()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Domo-Export-\(formattedDate()).json")
        do {
            try data.write(to: tempURL)
            exportURL = tempURL
            showExportShare = true
        } catch {
            backupMessage = "Export failed: \(error.localizedDescription)"
            showBackupAlert = true
        }
    }
    
    // MARK: - Backup
    
    private func backupData() {
        let data = buildExportPayload()
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            backupMessage = "Could not access Documents."
            showBackupAlert = true
            return
        }
        let fileURL = docsURL.appendingPathComponent("Domo-Backup-\(formattedDate()).json")
        do {
            try data.write(to: fileURL)
            backupMessage = "Backup saved to Files app.\n\(fileURL.lastPathComponent)"
            showBackupAlert = true
        } catch {
            backupMessage = "Backup failed: \(error.localizedDescription)"
            showBackupAlert = true
        }
    }
    
    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f.string(from: Date())
    }
    
    private func buildExportPayload() -> Data {
        var dict: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "currency": appState.currencyCode
        ]
        
        // Assets
        dict["assets"] = store.assets.map { a in
            ["name": a.name, "brand": a.brand, "category": a.categoryRaw,
             "purchasePrice": a.purchasePrice, "purchaseDate": ISO8601DateFormatter().string(from: a.purchaseDate)] as [String : Any]
        }
        
        // Warranties
        dict["warranties"] = store.warranties.map { w in
            ["productName": w.productName, "storeName": w.storeName, "price": w.price,
             "category": w.categoryRaw, "warrantyYears": w.warrantyYears,
             "purchaseDate": ISO8601DateFormatter().string(from: w.purchaseDate)] as [String : Any]
        }
        
        // Subscriptions
        dict["subscriptions"] = store.subscriptions.map { s in
            ["name": s.name, "price": s.price, "billingCycle": s.billingCycleRaw,
             "isActive": s.isActive, "renewalDate": ISO8601DateFormatter().string(from: s.renewalDate)] as [String : Any]
        }
        
        // Vehicles
        dict["vehicles"] = store.vehicles.map { v in
            ["make": v.make, "model": v.model, "year": v.year, "plate": v.plate,
             "currentMileage": v.currentMileage] as [String : Any]
        }
        
        // Insurance
        dict["insurancePolicies"] = store.insurancePolicies.map { p in
            ["type": p.typeRaw, "provider": p.provider, "policyNumber": p.policyNumber,
             "premium": p.premium ?? 0,
             "startDate": ISO8601DateFormatter().string(from: p.startDate),
             "expiryDate": ISO8601DateFormatter().string(from: p.expiryDate)] as [String : Any]
        }
        
        // Maintenance
        dict["maintenanceTasks"] = store.maintenanceTasks.map { t in
            ["title": t.title, "intervalMonths": t.intervalMonths,
             "estimatedCost": t.estimatedCost,
             "notes": t.notes ?? ""] as [String : Any]
        }
        
        return (try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }
}

// MARK: - Image Picker

private struct ImagePicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onPick(image)
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
    @State private var estimatedCost = ""
    @State private var enableReminder = true
    @State private var reminderDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task name (e.g. Boiler Service)", text: $title)
                    Stepper("Every \(intervalMonths) month\(intervalMonths > 1 ? "s" : "")",
                            value: $intervalMonths, in: 1...24)
                    TextField("Estimated cost (€)", text: $estimatedCost)
                        .keyboardType(.decimalPad)
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
            reminderDate: enableReminder ? reminderDate : nil,
            estimatedCost: Double(estimatedCost) ?? 0
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
