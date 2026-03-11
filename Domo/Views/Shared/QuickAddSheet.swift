import SwiftUI

// MARK: - QuickAddSheet

struct QuickAddSheet: View {

    @Environment(\.dismiss) private var dismiss

    // Sheet destinations
    @State private var destination: Destination?

    enum Destination: Identifiable {
        case document, warranty, subscription, vehicle, insurance, maintenance

        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(icon: "doc.text.fill",
                        label: "Add Document",
                        color: .purple,
                        destination: .document)

                    row(icon: "shield.lefthalf.filled",
                        label: "Add Warranty",
                        color: .green,
                        destination: .warranty)

                    row(icon: "arrow.triangle.2.circlepath",
                        label: "Add Subscription",
                        color: .blue,
                        destination: .subscription)

                    row(icon: "car.fill",
                        label: "Add Vehicle",
                        color: .orange,
                        destination: .vehicle)

                    row(icon: "lock.shield.fill",
                        label: "Add Insurance Policy",
                        color: .red,
                        destination: .insurance)

                    row(icon: "wrench.and.screwdriver.fill",
                        label: "Add Maintenance Task",
                        color: .teal,
                        destination: .maintenance)
                } header: {
                    Text("What would you like to add?")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .sheet(item: $destination) { dest in
                destinationView(for: dest)
            }
        }
    }

    // MARK: - Row

    private func row(icon: String, label: String, color: Color, destination dest: Destination) -> some View {
        Button {
            destination = dest
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 8))

                Text(label)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for dest: Destination) -> some View {
        switch dest {
        case .document:
            DocumentScannerView()
        case .warranty:
            AddWarrantyView()
        case .subscription:
            AddSubscriptionView()
        case .vehicle:
            AddVehicleView()
        case .insurance:
            AddPolicyView()
        case .maintenance:
            AddMaintenanceTaskView()
        }
    }
}

// MARK: - Preview

#Preview {
    QuickAddSheet()
        .environmentObject(DomoStore())
}
