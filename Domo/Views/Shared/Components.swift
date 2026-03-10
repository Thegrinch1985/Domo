import SwiftUI

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(tint)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WarrantyRow

struct WarrantyRow: View {
    let item: WarrantyItem
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.statusColor.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: item.category.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(item.statusColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.productName)
                    .font(.subheadline.weight(.medium))
                Text("Expires \(item.warrantyExpiry.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.daysRemaining)d")
                    .font(.callout.bold())
                    .foregroundStyle(item.statusColor)
                Text("left")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Spacer()
            if let action = action, let onAction = onAction {
                Button(action) { onAction() }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color(uiColor: .systemGray5))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Previews

#Preview("StatCard") {
    HStack {
        StatCard(title: "Monthly", value: "€132.94", subtitle: "5 services", icon: "creditcard.fill", tint: .blue)
        StatCard(title: "Warranties", value: "4", subtitle: "1 expiring", icon: "shield.fill", tint: .orange)
    }
    .padding()
}

#Preview("WarrantyRow") {
    List {
        ForEach(WarrantyItem.samples) { item in
            WarrantyRow(item: item)
        }
    }
}

#Preview("FilterChip") {
    HStack {
        FilterChip(title: "All", isSelected: true) {}
        FilterChip(title: "Electronics", isSelected: false) {}
    }
    .padding()
}
