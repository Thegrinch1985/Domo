import SwiftUI

struct InsuranceVaultView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DomoTheme.sectionSpacing) {
                    // Coverage summary
                    coverageSummary
                    
                    // Policies
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Policies")
                        
                        VStack(spacing: 10) {
                            ForEach(store.insurancePolicies) { policy in
                                NavigationLink(destination: PolicyDetailView(policy: policy)) {
                                    PolicyRow(policy: policy)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, DomoTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insurance Vault")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPolicyView()
            }
            .overlay {
                if store.insurancePolicies.isEmpty {
                    DomoEmptyState(
                        icon: "shield.checkered",
                        title: "No Policies",
                        subtitle: "Add your insurance policies to keep them safe and accessible.",
                        buttonTitle: "Add Policy",
                        action: { showAddSheet = true },
                        suggestions: [
                            .init(icon: "house.fill", label: "Home"),
                            .init(icon: "car.fill", label: "Car"),
                            .init(icon: "heart.fill", label: "Health"),
                            .init(icon: "airplane", label: "Travel"),
                            .init(icon: "person.fill", label: "Life"),
                        ]
                    ) { _ in
                        showAddSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Coverage Summary
    
    private var coverageSummary: some View {
        VStack(spacing: 0) {
            // Shield icon
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Text("\(store.insurancePolicies.count) Active Policies")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                if let totalPremium = totalAnnualPremium {
                    Text("\(totalPremium.formatted(.currency(code: "EUR"))) / year")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 18)
            
            // Coverage types
            HStack(spacing: 0) {
                ForEach(Array(coverageTypes.enumerated()), id: \.element) { index, type in
                    if index > 0 {
                        Rectangle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 1, height: 24)
                    }
                    
                    VStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(shortName(for: type))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(.white.opacity(0.08))
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.green.opacity(0.9), .teal, .cyan.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusLarge))
        .shadow(color: .green.opacity(0.25), radius: 20, y: 10)
    }
    
    private var totalAnnualPremium: Double? {
        let premiums = store.insurancePolicies.compactMap(\.premium)
        return premiums.isEmpty ? nil : premiums.reduce(0, +)
    }
    
    private var coverageTypes: [InsurancePolicy.PolicyType] {
        Array(Set(store.insurancePolicies.map(\.type))).sorted { $0.rawValue < $1.rawValue }
    }
    
    private func shortName(for type: InsurancePolicy.PolicyType) -> String {
        switch type {
        case .home: return "Home"
        case .car: return "Car"
        case .health: return "Health"
        case .travel: return "Travel"
        case .life: return "Life"
        case .other: return "Other"
        }
    }
}

// MARK: - PolicyRow

struct PolicyRow: View {
    let policy: InsurancePolicy
    
    var body: some View {
        HStack(spacing: 16) {
            GradientIcon(
                icon: policy.type.icon,
                gradient: gradientForType(policy.type),
                size: 50,
                iconScale: 0.42
            )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(policy.type.rawValue)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    Text(policy.provider)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(policy.policyNumber)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fontDesign(.monospaced)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if policy.isExpiringSoon {
                    Text("Expiring")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.orange.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text(policy.expiryDate.formatted(.dateTime.month(.abbreviated).year()))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    private func gradientForType(_ type: InsurancePolicy.PolicyType) -> LinearGradient {
        switch type {
        case .home: return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .car: return LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .health: return LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .travel: return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .life: return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other: return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - PolicyDetailView

struct PolicyDetailView: View {
    let policy: InsurancePolicy
    @EnvironmentObject private var store: DomoStore
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Hero
                VStack(spacing: 16) {
                    GradientIcon(
                        icon: policy.type.icon,
                        gradient: LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                        size: 64,
                        iconScale: 0.42
                    )
                    
                    Text(policy.type.rawValue)
                        .font(.title2.bold())
                    
                    Text(policy.provider)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Expiry badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(policy.isExpiringSoon ? .orange : .green)
                            .frame(width: 8, height: 8)
                        Text("\(policy.daysUntilExpiry) days remaining")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(policy.isExpiringSoon ? .orange : .green)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background((policy.isExpiringSoon ? Color.orange : .green).opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(DomoTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: DomoTheme.radiusLarge)
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                
                // Details
                VStack(spacing: 1) {
                    detailRow(label: "Policy Number", value: policy.policyNumber, mono: true)
                    detailRow(label: "Start Date", value: policy.startDate.formatted(date: .long, time: .omitted))
                    detailRow(label: "Expiry Date", value: policy.expiryDate.formatted(date: .long, time: .omitted),
                              highlight: policy.isExpiringSoon)
                    if let premium = policy.premium {
                        detailRow(label: "Annual Premium", value: premium.formatted(.currency(code: "EUR")))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                
                // Emergency contact
                if let phone = policy.emergencyPhone {
                    Link(destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!) {
                        HStack(spacing: 12) {
                            GradientIcon(
                                icon: "phone.fill",
                                gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                                size: 42
                            )
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Emergency Contact")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(phone)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(DomoTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                        )
                    }
                }
                
                // Attached documents
                policyDocumentsSection
            }
            .padding(DomoTheme.screenPadding)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(policy.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Documents Section
    
    private var policyDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Documents")
            
            let docs = store.documents(forPolicyID: policy.id)
            if docs.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "doc")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                    Text("No attached documents")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(DomoTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(docs) { doc in
                        HStack(spacing: 12) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title)
                                    .font(.subheadline.weight(.medium))
                                Text(doc.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(doc.category)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                        .padding(14)
                        .background(DomoTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                doc.linkedPolicyID = nil
                                store.refresh()
                            } label: {
                                Label("Unlink", systemImage: "link.badge.plus")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func detailRow(label: String, value: String, mono: Bool = false, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(highlight ? .orange : .primary)
                .fontDesign(mono ? .monospaced : .default)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DomoTheme.cardBackground)
    }
}

// MARK: - AddPolicyView

struct AddPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var policyType: InsurancePolicy.PolicyType = .home
    @State private var provider = ""
    @State private var policyNumber = ""
    @State private var startDate = Date()
    @State private var expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    @State private var premium = ""
    @State private var emergencyPhone = ""
    @State private var enableReminder = true
    @State private var reminderDate = Calendar.current.date(byAdding: .month, value: 11, to: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Policy Details") {
                    Picker("Type", selection: $policyType) {
                        ForEach(InsurancePolicy.PolicyType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    TextField("Provider", text: $provider)
                    TextField("Policy Number", text: $policyNumber)
                        .fontDesign(.monospaced)
                }
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
                Section("Optional") {
                    TextField("Annual Premium (€)", text: $premium)
                        .keyboardType(.decimalPad)
                    TextField("Emergency Phone", text: $emergencyPhone)
                        .keyboardType(.phonePad)
                }
                Section("Reminder") {
                    Toggle("Remind me before expiry", isOn: $enableReminder)
                    if enableReminder {
                        DatePicker("Reminder date", selection: $reminderDate, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(provider.isEmpty || policyNumber.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let policy = InsurancePolicy(
            type: policyType,
            provider: provider,
            policyNumber: policyNumber,
            startDate: startDate,
            expiryDate: expiryDate,
            premium: Double(premium),
            emergencyPhone: emergencyPhone.isEmpty ? nil : emergencyPhone,
            reminderDate: enableReminder ? reminderDate : nil
        )
        store.addPolicy(policy)
        dismiss()
    }
}

#Preview {
    InsuranceVaultView()
        .environmentObject(DomoStore())
        .preferredColorScheme(.dark)
}
