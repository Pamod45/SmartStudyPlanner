//
//  AIAssistantTabView.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-04-05.
//

import SwiftUI

struct AIAssistantTabView: View {
    @Environment(\.theme) var theme

    let subject: Subject
    let resources: [Resource]
    let studyPath: StudyPath?

    @State private var messages: [ChatMessage] = []
    @State private var selectedContext: ChatContext = .allDocs
    @State private var inputText: String = ""
    @State private var isThinking: Bool = false

    private var availableContexts: [ChatContext] {
        var ctxs: [ChatContext] = [.allDocs]
        ctxs += resources.map { .resource($0) }
        ctxs += (studyPath?.topics ?? []).map { .topic($0) }
        return ctxs
    }

    var body: some View {
        VStack(spacing: 0) {
            contextPickerStrip
                .padding(.bottom, theme.spacing.sm)
            messageArea
                .frame(maxHeight: .infinity)
            inputBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, theme.spacing.xl)
    }

    private var contextPickerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.sm) {
                ForEach(availableContexts) { ctx in
                    contextChip(ctx)
                }
            }
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, theme.spacing.xs)
        }
    }

    private func contextChip(_ ctx: ChatContext) -> some View {
        let isSelected = selectedContext == ctx
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedContext = ctx
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: ctx.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(ctx.label)
                    .font(theme.typography.bodySmall)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, 6)
            .background(isSelected ? theme.colors.primary : theme.colors.surface)
            .foregroundColor(isSelected ? theme.colors.textOnPrimary : theme.colors.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? theme.colors.primary : theme.colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var messageArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: theme.spacing.md) {
                    if messages.isEmpty && !isThinking {
                        emptyStateView.id("empty")
                    }
                    ForEach(messages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                    if isThinking {
                        thinkingBubble.id("thinking")
                    }
                }
                .padding(.horizontal, theme.spacing.xs)
                .padding(.vertical, theme.spacing.md)
            }
            .frame(maxHeight: .infinity)
            .onChange(of: messages.count) { _, _ in
                withAnimation {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isThinking) { _, thinking in
                if thinking {
                    withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.md) {
            Spacer(minLength: 80)
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(theme.colors.primary.opacity(0.5))
            Text("Ask anything about your study material")
                .font(theme.typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            Text("Select a context above to focus on a specific resource or topic, then type your question.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xl)
        }
        .frame(maxWidth: .infinity)
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isUser = msg.role == .user
        let isError = msg.role == .error

        return HStack(alignment: .top, spacing: 0) {
            if isUser { Spacer(minLength: 48) }

            Text(msg.content)
                .font(theme.typography.bodyMedium)
                .foregroundColor(
                    isUser  ? theme.colors.textOnPrimary :
                    isError ? theme.colors.error :
                              theme.colors.textPrimary
                )
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(
                    isUser  ? theme.colors.primary :
                    isError ? theme.colors.error.opacity(0.12) :
                              theme.colors.surface
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                .textSelection(.enabled)
                .frame(
                    maxWidth: UIScreen.main.bounds.width * 0.72,
                    alignment: isUser ? .trailing : .leading
                )

            if !isUser { Spacer(minLength: 48) }
        }
    }

    private var thinkingBubble: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    ThinkingDot(index: i, color: theme.colors.textSecondary)
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            Spacer()
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: theme.spacing.sm) {
            TextField("Ask a question…", text: $inputText, axis: .vertical)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, 10)
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                .lineLimit(1...4)
                .disabled(isThinking)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(canSend ? theme.colors.primary : theme.colors.textSecondary.opacity(0.4))
            }
            .disabled(!canSend)
            .buttonStyle(.plain)
            .padding(.bottom, 2)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.sm)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(role: .user, content: trimmed))
        inputText = ""
        isThinking = true

        let ctx = selectedContext
        let historySnapshot = messages
        let name = subject.name

        Task {
            do {
                let contextText = await AIAssistantService.shared.resolveContext(
                    ctx,
                    allResources: resources,
                    studyPath: studyPath
                )
                let reply = try await AIAssistantService.shared.send(
                    userMessage: trimmed,
                    contextText: contextText,
                    subjectName: name,
                    history: historySnapshot
                )
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: reply))
                    isThinking = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: .error, content: "Couldn't get a response. Check your connection and try again."))
                    isThinking = false
                }
            }
        }
    }
}

private struct ThinkingDot: View {
    let index: Int
    let color: Color

    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.18)
                ) {
                    opacity = 1.0
                }
            }
    }
}
