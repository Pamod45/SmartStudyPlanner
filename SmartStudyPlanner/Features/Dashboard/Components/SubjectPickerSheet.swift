import Combine
import SwiftUI

struct SubjectPickerSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    let subjects: [Subject]
    var onSelect: (Subject) -> Void

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Select Subject")
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular, in: Circle())
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.xl)
                .padding(.bottom, theme.spacing.md)

                if subjects.isEmpty {
                    Spacer()
                    Text("No subjects yet")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: theme.spacing.sm) {
                            ForEach(subjects) { subject in
                                Button {
                                    onSelect(subject)
                                    dismiss()
                                } label: {
                                    HStack(spacing: theme.spacing.md) {
                                        Circle()
                                            .fill(subject.color)
                                            .frame(width: 12, height: 12)
                                        Text(subject.name)
                                            .font(theme.typography.bodyMedium)
                                            .fontWeight(.semibold)
                                            .foregroundColor(theme.colors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(theme.colors.textSecondary)
                                    }
                                    .padding(theme.spacing.md)
                                    .background(theme.colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.lg)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
