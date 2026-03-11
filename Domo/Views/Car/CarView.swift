import SwiftUI

struct CarView: View {
    
    @EnvironmentObject private var store: DomoStore
    @State private var showAddLog = false
    @State private var showAddVehicle = false
    
    var body: some View {
        NavigationStack {
            Group {
                if store.vehicles.isEmpty {
                    emptyState
                } else if let vehicle = store.vehicles.first {
                    vehicleContent(vehicle)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Car")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if store.vehicles.isEmpty {
                            showAddVehicle = true
                        } else {
                            showAddLog = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddLog) {
                if let vehicle = store.vehicles.first {
                    AddServiceLogView(vehicle: vehicle)
                }
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView()
            }
        }
    }
    
    private func vehicleContent(_ vehicle: Vehicle) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DomoTheme.sectionSpacing) {
                // Vehicle hero card
                vehicleHeroCard(vehicle)
                
                // Service status gauges
                serviceStatusSection(vehicle)
                
                // Attached documents
                vehicleDocumentsSection(vehicle)
                
                // Service log
                serviceLogSection(vehicle)
            }
            .padding(.horizontal, DomoTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Vehicle Hero Card
    
    private func vehicleHeroCard(_ vehicle: Vehicle) -> some View {
        VStack(spacing: 0) {
            // Top section
            VStack(spacing: 12) {
                // Car icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: "car.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Text(vehicle.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text(vehicle.plate)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .kerning(3)
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            // Bottom stats
            HStack {
                VStack(spacing: 4) {
                    Text("\(vehicle.currentMileage.formatted())")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Current km")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 30)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(vehicle.serviceLogs.count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Services")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 30)
                
                Spacer()
                
                VStack(spacing: 4) {
                    let totalCost = vehicle.serviceLogs.compactMap(\.cost).reduce(0, +)
                    Text(totalCost.formatted(.currency(code: "EUR")))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Total spend")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(.white.opacity(0.08))
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.purple, .indigo, .blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusLarge))
        .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)
    }
    
    // MARK: - Service Status
    
    private func serviceStatusSection(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Service Status")
            
            HStack(spacing: DomoTheme.itemSpacing) {
                // Distance to service
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "gauge.medium")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(vehicle.isServiceDue ? .orange : .green)
                        Text("Next Service")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(vehicle.mileageUntilService.formatted()) km")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(vehicle.isServiceDue ? .orange : .primary)
                    
                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            
                            let progress = min(1.0, max(0, 1.0 - Double(vehicle.mileageUntilService) / Double(max(1, vehicle.nextServiceMileage - (vehicle.currentMileage - vehicle.mileageUntilService)))))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(vehicle.isServiceDue
                                      ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .domoCard()
                
                // Target mileage
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                        Text("Target")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(vehicle.nextServiceMileage.formatted())")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text("km")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                }
                .domoCard()
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Vehicle Documents
    
    private func vehicleDocumentsSection(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Documents")
            
            let docs = store.documents(forVehicleID: vehicle.id)
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
                                .foregroundStyle(.purple)
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
                                doc.linkedVehicleID = nil
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
    
    // MARK: - Service Log
    
    private func serviceLogSection(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Service History", action: "\(vehicle.serviceLogs.count) records") { }
            
            VStack(spacing: 8) {
                ForEach(vehicle.serviceLogs.sorted { $0.date > $1.date }) { log in
                    ServiceLogRow(log: log)
                }
            }
        }
    }
    
    private var emptyState: some View {
        DomoEmptyState(
            icon: "car.fill",
            title: "No Vehicle Added",
            subtitle: "Add your car to track maintenance and service history.",
            buttonTitle: "Add Vehicle"
        ) {
            showAddVehicle = true
        }
    }
}

// MARK: - ServiceLogRow

struct ServiceLogRow: View {
    let log: ServiceLog
    
    var body: some View {
        HStack(spacing: 14) {
            GradientIcon(
                icon: log.type.icon,
                gradient: gradientForType(log.type),
                size: 42
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.type.rawValue)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    Text("·")
                    Text("\(log.mileage.formatted()) km")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let cost = log.cost {
                Text(cost.formatted(.currency(code: "EUR")))
                    .font(.subheadline.bold())
            }
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    private func gradientForType(_ type: ServiceLog.ServiceType) -> LinearGradient {
        switch type {
        case .oilChange: return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tires: return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .brakes: return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .fullService: return LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .inspection: return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other: return LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - AddServiceLogView

struct AddServiceLogView: View {
    let vehicle: Vehicle
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
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(mileage.isEmpty)
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
        store.addServiceLog(log, to: vehicle)
        dismiss()
    }
}

// MARK: - AddVehicleView

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DomoStore
    
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var plate = ""
    @State private var currentMileage = ""
    @State private var nextServiceMileage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Info") {
                    TextField("Make (e.g. BMW)", text: $make)
                    TextField("Model (e.g. 3 Series)", text: $model)
                    Stepper("Year: \(year)", value: $year, in: 1990...Calendar.current.component(.year, from: Date()) + 1)
                    TextField("Plate Number", text: $plate)
                        .textInputAutocapitalization(.characters)
                }
                Section("Mileage") {
                    TextField("Current Mileage (km)", text: $currentMileage)
                        .keyboardType(.numberPad)
                    TextField("Next Service Mileage (km)", text: $nextServiceMileage)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(make.isEmpty || model.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let vehicle = Vehicle(
            make: make,
            model: model,
            year: year,
            plate: plate.uppercased(),
            currentMileage: Int(currentMileage) ?? 0,
            nextServiceMileage: Int(nextServiceMileage) ?? 10000
        )
        store.addVehicle(vehicle)
        dismiss()
    }
}

#Preview {
    CarView()
        .environmentObject(DomoStore())
        .preferredColorScheme(.dark)
}
