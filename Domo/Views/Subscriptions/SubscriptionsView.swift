import SwiftUI

struct SubscriptionsView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                // Summary card
                spendSummaryCard
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                
                Section("Active") {
                    ForEach(store.subscriptions.filter(\.isActive)) { sub in
                        SubscriptionRow(sub: sub) {
                            store.toggleSubscription(sub)
                        }
                    }
                    .onDelete { offsets in store.deleteSubscription(at: offsets) }
                }
                
                let inactive = store.subscriptions.filter { !$0.isActive }
                if !inactive.isEmpty {
                    Section("Inactive") {
                        ForEach(inactive) { sub in
                            SubscriptionRow(sub: sub) {
                                store.toggleSubscription(sub)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddSubscriptionView()
            }
        }
    }
    
    private var spendSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly spend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.totalMonthlySpend.formatted(.currency(code: "EUR")))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Yearly")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.totalYearlySpend.formatted(.currency(code: "EUR")))
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(.blue.gradient.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.blue.opacity(0.2))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - SubscriptionRow

struct SubscriptionRow: View {
    let sub: Subscription
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)
                    .frame(width: 44, height: 44)
                Image(systemName: sub.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(sub.isActive ? .primary : .secondary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(sub.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(sub.isActive ? .primary : .secondary)
                Text("Renews \(sub.renewalDate.formatted(.dateTime.month().day()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Price + toggle
            VStack(alignment: .trailing, spacing: 4) {
                Text(sub.price.formatted(.currency(code: "EUR")))
                    .font(.subheadline.bold())
                Text(sub.billingCycle.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .leading) {
            Button(sub.isActive ? "Pause" : "Resume") { onToggle() }
                .tint(sub.isActive ? .orange : .green)
        }
    }
}

// MARK: - AddSubscriptionView (Placeholder)

struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var name = ""
    @State private var price = ""
    @State private var cycle: Subscription.BillingCycle = .monthly
    @State private var category: Subscription.SubscriptionCategory = .entertainment
    @State private var renewalDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Name (e.g. Netflix)", text: $name)
                    TextField("Price (€)", text: $price)
                        .keyboardType(.decimalPad)
                    Picker("Billing", selection: $cycle) {
                        ForEach(Subscription.BillingCycle.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    Picker("Category", selection: $category) {
                        ForEach(Subscription.SubscriptionCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                }
                Section("Renewal") {
                    DatePicker("Next renewal", selection: $renewalDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let sub = Subscription(
            name: name,
            price: Double(price) ?? 0,
            billingCycle: cycle,
            renewalDate: renewalDate,
            category: category,
            iconName: "dollarsign.circle.fill",
            colorHex: "#007AFF"
        )
        store.addSubscription(sub)
        dismiss()
    }
}

#Preview {
    SubscriptionsView()
        .environmentObject(DomoStore())
}
