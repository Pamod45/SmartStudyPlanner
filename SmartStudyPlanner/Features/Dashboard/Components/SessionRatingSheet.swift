import SwiftUI

struct SessionRatingSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let session: StudySession
    var onRate: (Int?) -> Void

    @State private var selected: Int? = nil

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.colors.border)
                .frame(width: 40, height: 4)
                .padding(.top, theme.spacing.md)

            VStack(spacing: theme.spacing.xs) {
                Text("Session Complete!")
                    .font(theme.typography.headingMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(session.title)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            Text("How did it go?")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)

            HStack(spacing: theme.spacing.lg) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selected = star
                        }
                    } label: {
                        Image(systemName: star <= (selected ?? 0) ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundColor(star <= (selected ?? 0) ? .yellow : theme.colors.border)
                            .scaleEffect(selected == star ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
                    }
                }
            }
            .padding(.vertical, theme.spacing.sm)

            Button {
                onRate(selected)
                dismiss()
            } label: {
                Text(selected != nil ? "Save Rating" : "Skip")
                    .font(theme.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.md)
                    .background(selected != nil ? theme.colors.primary : theme.colors.textSecondary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, theme.spacing.lg)

            Spacer()
        }
        .padding(.horizontal, theme.spacing.lg)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
    }
}
