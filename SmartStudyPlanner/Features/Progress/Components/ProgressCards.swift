import SwiftUI

// Small display cards used by the Progress summary screen.
struct StatCard: View {
    @Environment(\.theme) var theme
    let item: StatItem

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(item.iconColor)
                    .frame(width: 32, height: 32)
                    .background(item.iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.sm))

                Spacer()

                if let badge = item.badge {
                    Text(badge)
                        .font(theme.typography.labelSmall.weight(.bold))
                        .foregroundColor(item.badgeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(item.badgeColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Text(item.value)
                .font(theme.typography.headingLarge)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(item.label)
                .font(theme.typography.label)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textSecondary)
                .tracking(1.2)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.label): \(item.value)")
        .accessibilityValue(item.badge != nil ? "Status: \(item.badge!)" : "")
    }
}

// Shows one subject's calculated mastery value and status label.
struct SubjectProgressCard: View {
    @Environment(\.theme) var theme
    let item: SubjectProgress

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(item.subtitle)
                        .font(theme.typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textSecondary)
                        .tracking(1.0)
                }

                Spacer()

                Text(item.status.rawValue)
                    .font(theme.typography.labelSmall.weight(.bold))
                    .foregroundColor(item.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.status.color.opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.onSurface)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color)
                            .frame(width: geo.size.width * item.mastery, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("MASTERY")
                        .font(theme.typography.label)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textSecondary)
                        .tracking(1.0)

                    Spacer()

                    Text("\(Int(item.mastery * 100))%")
                        .font(theme.typography.bodySmall)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Subject: \(item.name), \(item.subtitle). Status: \(item.status.rawValue)")
        .accessibilityValue("Mastery: \(Int(item.mastery * 100))%")
    }
}

// Shows one generated insight from ProgressViewModel in a readable card.
struct InsightCard: View {
    @Environment(\.theme) var theme
    let item: InsightItem

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            ZStack {
                Rectangle()
                    .fill(item.tagColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .cornerRadius(theme.radius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.lg)
                            .stroke(item.tagColor.opacity(0.35), lineWidth: 1)
                    )
                Image(systemName: item.icon)
                    .font(theme.typography.headingMedium.weight(.semibold))
                    .foregroundColor(item.tagColor)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(item.tag)
                    .font(theme.typography.labelSmall.weight(.bold))
                    .foregroundColor(item.tagColor)
                    .tracking(1.1)

                Text(item.title)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(item.body)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(theme.spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.tag): \(item.title)")
        .accessibilityValue(item.body)
    }
}
