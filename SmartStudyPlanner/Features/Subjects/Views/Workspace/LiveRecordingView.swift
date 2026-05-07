import SwiftUI
import Combine

struct TranscriptLine: Identifiable {
    let id = UUID()
    let timestamp: String
    let text: String
}

struct LiveRecordingView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onSave: (Resource) -> Void

    @StateObject private var audioService = AudioTranscriptionService()
    
    @State private var wavePhase: Double = 0
    @State private var waveTimer: AnyCancellable? = nil

    private var formattedTime: String {
        let m = audioService.elapsedSeconds / 60
        let s = audioService.elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, theme.spacing.lg)
                    .padding(.horizontal, theme.spacing.lg)

                Spacer()

                waveformView
                    .padding(.vertical, theme.spacing.xl)

                Spacer()

                controlsSection
                    .padding(.horizontal, theme.spacing.xl)

                Spacer()

                transcriptPanel
            }
        }
        
        .onDisappear {
            if audioService.isRecording {
                audioService.stopRecording()
                stopTimers()
            }
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live Recording")
                    .font(theme.typography.headingLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                HStack(spacing: theme.spacing.xs) {
                    Circle()
                        .fill(audioService.isRecording && !audioService.isPaused ? .green : theme.colors.textSecondary)
                        .frame(width: 8, height: 8)

                    Text("\(formattedTime) • \(audioService.isRecording && !audioService.isPaused ? "TRANSCRIBING" : "PAUSED")")
                        .font(theme.typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .clipShape(Circle())
            }
        }
    }

    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<32, id: \.self) { index in
                let height = waveBarHeight(for: index)
                Capsule()
                    .fill(theme.colors.primary.opacity(audioService.isPaused ? 0.3 : 0.8))
                    .frame(width: 4, height: height)
                    .animation(.easeInOut(duration: 0.15), value: height)
            }
        }
        .frame(height: 60)
    }

    private func waveBarHeight(for index: Int) -> CGFloat {
        guard !audioService.isPaused else { return 8 }
        let base = sin(Double(index) * 0.5 + wavePhase) * 20 + 24
        let variation = sin(Double(index) * 1.2 + wavePhase * 1.5) * 10
        return max(8, CGFloat(base + variation))
    }

    private var controlsSection: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: theme.spacing.sm) {
                Button {
                    audioService.pauseRecording()
                } label: {
                    Image(systemName: audioService.isPaused ? "play.fill" : "pause")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 56, height: 56)
                        .background(theme.colors.surface)
                        .clipShape(Circle())
                }

                Text("PAUSE")
                    .font(theme.typography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            Button {
                if !audioService.isRecording && audioService.elapsedSeconds == 0 {
                    audioService.startRecording()
                    startTimers()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.colors.primary)
                        .frame(width: 72, height: 72)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(theme.colors.textOnPrimary)
                }
                .shadow(color: theme.colors.primary.opacity(0.5), radius: 16, x: 0, y: 0)
            }

            Spacer()

            VStack(spacing: theme.spacing.sm) {
                Button {
                    save()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 56, height: 56)
                        .background(theme.colors.surface)
                        .clipShape(Circle())
                }

                Text("SAVE")
                    .font(theme.typography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()
        }
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("REAL-TIME TRANSCRIPT")
                    .font(theme.typography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(theme.colors.primary)
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)

            ScrollView(showsIndicators: false) {
                ScrollViewReader { proxy in
                    highlightedLiveTranscript
                        .font(theme.typography.headingMedium)
                        .fontWeight(.medium)
                        .lineSpacing(8)
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("transcriptText")
                        .onChange(of: audioService.transcriptText) { _ in
                            withAnimation {
                                proxy.scrollTo("transcriptText", anchor: .bottom)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
        .ignoresSafeArea(edges: .bottom)
    }

    private var highlightedLiveTranscript: Text {
        let segments = audioService.segments
        guard !segments.isEmpty else {
            return Text(audioService.transcriptText.isEmpty ? (audioService.isRecording ? "Listening..." : "Tap the microphone to start recording.") : audioService.transcriptText)
                .foregroundColor(theme.colors.textSecondary.opacity(0.6))
        }
        
        var combinedText = Text("")
        let activeIndex = segments.count - 1
        
        for (index, segment) in segments.enumerated() {
            let isActive = index == activeIndex
            let wordText = Text(segment.text + " ")
                .foregroundColor(isActive ? theme.colors.primary : theme.colors.textSecondary.opacity(0.4))
            combinedText = combinedText + wordText
        }
        return combinedText
    }

    private func startTimers() {
        waveTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in wavePhase += 0.15 }
    }

    private func stopTimers() {
        waveTimer?.cancel()
    }

    private func save() {
        stopTimers()
        audioService.stopRecording()
        
        guard let url = audioService.audioFileURL else {
            dismiss()
            return
        }
        
        let resource = Resource(
            name: "Recording \(Date().formatted(date: .abbreviated, time: .shortened))",
            resourceType: .recording,
            size: formattedTime,
            content: audioService.getJSONTranscript(),
            localFilePath: url.lastPathComponent
        )
        onSave(resource)
        dismiss()
    }
}
