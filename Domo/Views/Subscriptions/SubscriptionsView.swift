import SwiftUI

struct SubscriptionsView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DomoTheme.sectionSpacing) {
                    // Spend hero card
                    spendHeroCard
                    
                    // Active subscriptions
                    let active = store.subscriptions.filter(\.isActive)
                    if !active.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Active")
                            VStack(spacing: 8) {
                                ForEach(active) { sub in
                                    SubscriptionRow(sub: sub) {
                                        withAnimation(.spring(response: 0.3)) {
                                            store.toggleSubscription(sub)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Inactive subscriptions
                    let inactive = store.subscriptions.filter { !$0.isActive }
                    if !inactive.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Paused")
                            VStack(spacing: 8) {
                                ForEach(inactive) { sub in
                                    SubscriptionRow(sub: sub) {
                                        withAnimation(.spring(response: 0.3)) {
                                            store.toggleSubscription(sub)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DomoTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Subscriptions")
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
                AddSubscriptionView()
            }
            .overlay {
                if store.subscriptions.isEmpty {
                    DomoEmptyState(
                        icon: "arrow.triangle.2.circlepath",
                        title: "No Subscriptions",
                        subtitle: "Track your recurring payments to stay on top of your spending.",
                        buttonTitle: "Add Subscription"
                    ) {
                        showAddSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Spend Hero Card
    
    private var spendHeroCard: some View {
        VStack(spacing: 0) {
            // Top section with monthly spend
            VStack(spacing: 8) {
                Text("Monthly Spend")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(store.totalMonthlySpend.formatted(.currency(code: "EUR")))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            // Bottom section with yearly
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yearly estimate")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(store.totalYearlySpend.formatted(.currency(code: "EUR")))
                        .font(.title3.bold())
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(store.subscriptions.filter(\.isActive).count) services")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(20)
            .background(.white.opacity(0.1))
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.blue, .indigo, .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusLarge))
        .shadow(color: .blue.opacity(0.3), radius: 20, y: 10)
    }
}

// MARK: - SubscriptionRow

struct SubscriptionRow: View {
    let sub: Subscription
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Colored icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: sub.colorHex).gradient)
                    .frame(width: 46, height: 46)
                Image(systemName: sub.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .opacity(sub.isActive ? 1 : 0.5)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(sub.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(sub.isActive ? .primary : .secondary)
                HStack(spacing: 4) {
                    Text(sub.billingCycle.rawValue)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    if sub.isActive {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("Renews \(sub.renewalDate.formatted(.dateTime.month().day()))")
                            .font(.caption)
                            .foregroundStyle(sub.daysUntilRenewal <= 3 ? .orange : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // Price
            Text(sub.price.formatted(.currency(code: "EUR")))
                .font(.subheadline.bold())
                .foregroundStyle(sub.isActive ? .primary : .secondary)
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .contextMenu {
            Button {
                onToggle()
            } label: {
                Label(sub.isActive ? "Pause" : "Resume",
                      systemImage: sub.isActive ? "pause.circle" : "play.circle")
            }
            
            Button(role: .destructive) {
                // TODO: delete
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - AddSubscriptionView

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
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
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
        .preferredColorScheme(.dark)
}
