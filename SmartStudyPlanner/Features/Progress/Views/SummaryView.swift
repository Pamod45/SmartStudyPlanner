import SwiftUI

struct SummaryView: View {
    @Environment(\.theme) var theme
    @ObservedObject var vm: ProgressViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                if vm.stats.isEmpty && vm.subjectProgressItems.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: theme.spacing.md), GridItem(.flexible(), spacing: theme.spacing.md)],
                        spacing: theme.spacing.md
                    ) {
                        ForEach(vm.stats.indices, id: \.self) { i in
                            StatCard(item: vm.stats[i])
                        }
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Subject Performance")
                            .font(theme.typography.headingSmall)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)

                        ForEach(vm.subjectProgressItems.indices, id: \.self) { i in
                            SubjectProgressCard(item: vm.subjectProgressItems[i])
                        }
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("AI Insights")
                            .font(theme.typography.headingSmall)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)

                        VStack(spacing: theme.spacing.md) {
                            ForEach(vm.insights.indices, id: \.self) { i in
                                InsightCard(item: vm.insights[i])
                                    .background(theme.colors.onSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                            }
                        }
                        .padding(theme.spacing.sm)
                        .background(theme.colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                    }
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, theme.spacing.md)
            .padding(.bottom, theme.spacing.xxl)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.md) {
            Spacer().frame(height: theme.spacing.xxl)
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary)
            Text("No progress data yet")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
            Text("Complete some study sessions to see your progress")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
