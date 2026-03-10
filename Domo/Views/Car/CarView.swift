import SwiftUI

struct CarView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddLog = false
    
    var body: some View {
        NavigationStack {
            Group {
                if store.vehicles.isEmpty {
                    emptyState
                } else if let vehicle = store.vehicles.first {
                    vehicleContent(vehicle)
                }
            }
            .navigationTitle("My Car")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(store.vehicles.isEmpty)
                }
            }
            .sheet(isPresented: $showAddLog) {
                if let vehicle = store.vehicles.first {
                    AddServiceLogView(vehicleID: vehicle.id)
                }
            }
        }
    }
    
    private func vehicleContent(_ vehicle: Vehicle) -> some View {
        List {
            // Vehicle card
            Section {
                vehicleCard(vehicle)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            
            // Service status
            Section("Service Status") {
                LabeledContent("Current Mileage") {
                    Text("\(vehicle.currentMileage.formatted()) km")
                        .fontWeight(.medium)
                }
                LabeledContent("Next Service") {
                    Text("\(vehicle.nextServiceMileage.formatted()) km")
                        .foregroundStyle(vehicle.isServiceDue ? .orange : .primary)
                        .fontWeight(.medium)
                }
                LabeledContent("Distance Remaining") {
                    Text("\(vehicle.mileageUntilService.formatted()) km")
                        .foregroundStyle(vehicle.isServiceDue ? .orange : .secondary)
                }
            }
            
            // Service log
            Section("Service Log") {
                ForEach(vehicle.serviceLogs.sorted { $0.date > $1.date }) { log in
                    ServiceLogRow(log: log)
                }
            }
        }
    }
    
    private func vehicleCard(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(vehicle.displayName, systemImage: "car.fill")
                .font(.title2.bold())
            Text(vehicle.plate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var emptyState: some View {
        ContentUnavailableView(
            "No Vehicle Added",
            systemImage: "car.fill",
            description: Text("Add your car to track maintenance and service history.")
        )
    }
}

// MARK: - ServiceLogRow

struct ServiceLogRow: View {
    let log: ServiceLog
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: log.type.icon)
                .frame(width: 28)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(log.type.rawValue)
                    .font(.subheadline.weight(.medium))
                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                if let cost = log.cost {
                    Text(cost.formatted(.currency(code: "EUR")))
                        .font(.subheadline)
                }
                Text("\(log.mileage.formatted()) km")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - AddServiceLogView

struct AddServiceLogView: View {
    let vehicleID: UUID
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var serviceType: ServiceLog.ServiceType = .oilChange
    @State private var date = Date()
    @State private var mileage = ""
    @State private var cost = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Service Details") {
                    Picker("Type", selection: $serviceType) {
                        ForEach(ServiceLog.ServiceType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Mileage (km)", text: $mileage)
                        .keyboardType(.numberPad)
                    TextField("Cost (€, optional)", text: $cost)
                        .keyboardType(.decimalPad)
                }
                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(mileage.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let log = ServiceLog(
            type: serviceType,
            date: date,
            mileage: Int(mileage) ?? 0,
            cost: Double(cost),
            notes: notes.isEmpty ? nil : notes
        )
        store.addServiceLog(log, to: vehicleID)
        dismiss()
    }
}

#Preview {
    CarView()
        .environmentObject(DomoStore())
}
