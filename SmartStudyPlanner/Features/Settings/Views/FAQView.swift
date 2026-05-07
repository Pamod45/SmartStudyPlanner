import SwiftUI

struct FAQView: View {
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
                    VStack(spacing: theme.spacing.md) {
                        faqItem(
                            question: "How do I convert handwritten notes?",
                            answer: "Go to your Subject Workspace and tap the 'Scanner' icon. You can scan physical notes, and our system will use OCR to extract the text and save it as a digital, editable Note."
                        )
                        faqItem(
                            question: "How can I add resources to a Deadline?",
                            answer: "When you create or edit a Deadline inside a Subject Workspace, you can link existing PDFs, URLs, and Notes directly to it so everything is in one place."
                        )
                        faqItem(
                            question: "How do Study Paths work?",
                            answer: "Our intelligent planner analyzes all the resources (PDFs, Notes) inside a subject and generates a step-by-step curriculum to help you master the material progressively."
                        )
                        faqItem(
                            question: "How are quizzes generated?",
                            answer: "Open any Note or scanned text and tap the 'Generate Quiz' option. The app reads the content and automatically generates multiple-choice questions to test your knowledge."
                        )
                    }
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
            Text("FAQ")
                .font(theme.typography.headingMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            RoundedIconButton(icon: "chevron.left") {}.opacity(0)
        }
    }
    
    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(question)
                .font(theme.typography.bodyLarge.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            Text(answer)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl)
                .stroke(theme.colors.border.opacity(0.4), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
    .environment(\.theme, AppTheme.defaultTheme)
}
