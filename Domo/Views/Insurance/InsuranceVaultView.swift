import SwiftUI

struct InsuranceVaultView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.insurancePolicies) { policy in
                    NavigationLink(destination: PolicyDetailView(policy: policy)) {
                        PolicyRow(policy: policy)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: store.deletePolicy)
            }
            .listStyle(.plain)
            .navigationTitle("Insurance Vault")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPolicyView()
            }
            .overlay {
                if store.insurancePolicies.isEmpty {
                    ContentUnavailableView(
                        "No Policies",
                        systemImage: "lock.shield.fill",
                        description: Text("Add your insurance policies to keep them safe and accessible.")
                    )
                }
            }
        }
    }
}

// MARK: - PolicyRow

struct PolicyRow: View {
    let policy: InsurancePolicy
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.quaternary)
                    .frame(width: 52, height: 52)
                Image(systemName: policy.type.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(policy.type.rawValue)
                    .font(.subheadline.weight(.semibold))
                Text(policy.provider)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(policy.policyNumber)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fontDesign(.monospaced)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(policy.expiryDate.formatted(.dateTime.month().year()))
                    .font(.caption.bold())
                    .foregroundStyle(policy.isExpiringSoon ? .orange : .secondary)
                if policy.isExpiringSoon {
                    Text("Expiring soon")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.vertical, 4)
    }
}

// MARK: - PolicyDetailView

struct PolicyDetailView: View {
    let policy: InsurancePolicy
    
    var body: some View {
        List {
            Section("Policy") {
                LabeledContent("Type", value: policy.type.rawValue)
                LabeledContent("Provider", value: policy.provider)
                LabeledContent("Policy Number", value: policy.policyNumber)
            }
            
            Section("Coverage Period") {
                LabeledContent("Start Date", value: policy.startDate.formatted(date: .long, time: .omitted))
                LabeledContent("Expiry Date") {
                    Text(policy.expiryDate.formatted(date: .long, time: .omitted))
                        .foregroundStyle(policy.isExpiringSoon ? .orange : .primary)
                }
                LabeledContent("Days Remaining") {
                    Text("\(policy.daysUntilExpiry) days")
                        .foregroundStyle(policy.isExpiringSoon ? .orange : .secondary)
                }
            }
            
            if let premium = policy.premium {
                Section("Premium") {
                    LabeledContent("Annual Premium", value: premium.formatted(.currency(code: "EUR")))
                }
            }
            
            if let phone = policy.emergencyPhone {
                Section("Emergency") {
                    Link(destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!) {
                        Label(phone, systemImage: "phone.fill")
                    }
                }
            }
        }
        .navigationTitle(policy.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Policy Details") {
                    Picker("Type", selection: $policyType) {
                        ForEach(InsurancePolicy.PolicyType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
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
            }
            .navigationTitle("Add Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
            emergencyPhone: emergencyPhone.isEmpty ? nil : emergencyPhone
        )
        store.addPolicy(policy)
        dismiss()
    }
}

#Preview {
    InsuranceVaultView()
        .environmentObject(DomoStore())
}
