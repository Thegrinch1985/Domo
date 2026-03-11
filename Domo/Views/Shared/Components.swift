import SwiftUI

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    var action: (() -> Void)? = nil
    
    init(title: String, value: String, subtitle: String, icon: String, tint: Color, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.gradient = LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        self.action = action
    }
    
    init(title: String, value: String, subtitle: String, icon: String, gradient: LinearGradient, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(gradient)
                }
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .domoCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WarrantyRow

struct WarrantyRow: View {
    let item: WarrantyItem
    
    var body: some View {
        HStack(spacing: 14) {
            // Gradient icon
            GradientIcon(
                icon: item.category.icon,
                gradient: LinearGradient(
                    colors: [item.statusColor, item.statusColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                size: 46
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    Text(item.storeName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("Expires \(item.warrantyExpiry.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Status pill
            Text("\(item.daysRemaining)d")
                .font(.caption.bold())
                .foregroundStyle(item.statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(item.statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(DomoTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DomoTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DomoTheme.radiusMedium)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
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
                .font(.title3.bold())
            Spacer()
            if let action = action, let onAction = onAction {
                Button {
                    onAction()
                } label: {
                    HStack(spacing: 4) {
                        Text(action)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
                }
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
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            DomoTheme.brandGradient
                        } else {
                            LinearGradient(colors: [Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(isSelected ? 0 : 0.06), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - EmptyStateView

struct DomoEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(.blue.opacity(0.6))
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }
            
            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(DomoTheme.brandGradient)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .padding(40)
    }
}

// MARK: - Profile Avatar

struct ProfileAvatar: View {
    let initials: String
    var size: CGFloat = 36
    
    var body: some View {
        ZStack {
            Circle()
                .fill(DomoTheme.brandGradient)
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Previews

#Preview("StatCard") {
    HStack {
        StatCard(title: "Monthly", value: "€132.94", subtitle: "5 services", icon: "creditcard.fill", tint: .blue)
        StatCard(title: "Warranties", value: "4", subtitle: "1 expiring", icon: "shield.fill", tint: .orange)
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("WarrantyRow") {
    VStack {
        WarrantyRow(item: WarrantyItem(
            productName: "MacBook Pro",
            storeName: "Apple Store",
            purchaseDate: .now,
            warrantyYears: 1,
            price: 2799,
            category: .electronics
        ))
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("FilterChip") {
    HStack {
        FilterChip(title: "All", isSelected: true) {}
        FilterChip(title: "Electronics", isSelected: false) {}
    }
    .padding()
    .preferredColorScheme(.dark)
}
