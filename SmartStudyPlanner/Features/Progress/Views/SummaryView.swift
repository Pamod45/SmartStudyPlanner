import SwiftUI

struct SummaryView: View {
    @Environment(\.theme) var theme

    let stats: [StatItem] = StatItem.samples
    let subjects: [SubjectProgress] = SubjectProgress.samples
    let insights: [InsightItem] = InsightItem.samples

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: theme.spacing.md), GridItem(.flexible(), spacing: theme.spacing.md)],
                    spacing: theme.spacing.md
                ) {
                    ForEach(stats.indices, id: \.self) { i in
                        StatCard(item: stats[i])
                    }
                }

                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Subject Performance")
                        .font(theme.typography.headingSmall)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    ForEach(subjects.indices, id: \.self) { i in
                        SubjectProgressCard(item: subjects[i])
                    }
                }

                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("AI Insights")
                        .font(theme.typography.headingSmall)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    VStack(spacing: theme.spacing.md) {
                        ForEach(insights.indices, id: \.self) { i in
                            InsightCard(item: insights[i])
                                .background(theme.colors.onSurface)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                        }
                    }
                    .padding(theme.spacing.sm)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, theme.spacing.md)
            .padding(.bottom, theme.spacing.xxl)
        }
    }
}
