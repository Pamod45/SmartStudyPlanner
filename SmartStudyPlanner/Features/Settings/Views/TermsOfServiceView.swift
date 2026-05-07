import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.lg)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.spacing.lg) {
                        
                        Text("Terms of Service")
                            .font(theme.typography.headingLarge)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("Last updated: May 2026")
                            .font(theme.typography.label)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Group {
                            section(title: "1. Acceptance of Terms", content: "By accessing or using the SmartStudyPlanner application, you agree to be bound by these Terms of Service. If you do not agree, please do not use the application.")
                            
                            section(title: "2. User Data and Privacy", content: "Your study data, including notes, deadlines, and schedules, are stored locally on your device and synced to Firebase Cloud services. We respect your privacy and do not sell your personal data to third parties.")
                            
                            section(title: "3. AI Services", content: "Certain features, such as Study Paths and Quiz Generation, utilize artificial intelligence. While we strive for accuracy, the generated content is for educational assistance and should not replace formal academic guidance.")
                            
                            section(title: "4. Account Responsibilities", content: "You are responsible for safeguarding the password that you use to access the service and for any activities or actions under your password.")
                            
                            section(title: "5. Termination", content: "We may terminate or suspend access to our service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.")
                        }
                    }
                    .padding(theme.spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.xl)
                            .stroke(theme.colors.border.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var header: some View {
        HStack {
            RoundedIconButton(icon: "chevron.left") { dismiss() }
            Spacer()
            Text("Terms")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon: "chevron.left") {}.opacity(0)
        }
    }
    
    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text(content)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
    .environment(\.theme, AppTheme.defaultTheme)
}
