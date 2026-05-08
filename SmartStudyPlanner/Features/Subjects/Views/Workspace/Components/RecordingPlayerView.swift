import SwiftUI
import AVFoundation

// Plays a saved recording resource and highlights transcript segments as the audio time advances.
struct RecordingPlayerView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    let resource: Resource
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var hasError: Bool = false
    @State private var segments: [TranscriptSegment] = []
    
    private var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    private var formattedDuration: String {
        formatTime(duration)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button {
                        audioPlayer?.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.surface)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(resource.name)
                        .font(theme.typography.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.lg)
                .padding(.bottom, theme.spacing.md)
                
                Divider().background(theme.colors.border.opacity(0.3))
                
                if hasError {
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(theme.colors.textSecondary)
                        Text("Audio file not found or invalid.")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .padding(.top, theme.spacing.sm)
                        Spacer()
                    }
                } else {
                    VStack(spacing: theme.spacing.md) {
                        Slider(value: $currentTime, in: 0...max(duration, 1), onEditingChanged: { editing in
                            if !editing {
                                audioPlayer?.currentTime = currentTime
                            }
                        })
                        .accentColor(theme.colors.primary)
                        
                        HStack {
                            Text(formattedCurrentTime)
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.colors.textSecondary)
                            Spacer()
                            Text(formattedDuration)
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        Button {
                            togglePlayPause()
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(theme.colors.primary)
                        }
                    }
                    .padding(theme.spacing.xl)
                    .background(theme.colors.surface)
                    .cornerRadius(theme.radius.xl)
                    .padding(theme.spacing.lg)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("TRANSCRIPT")
                                .font(theme.typography.labelSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Spacer()
                            
                            Image(systemName: "text.quote")
                                .foregroundColor(theme.colors.primary)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.vertical, theme.spacing.md)
                        
                        ScrollView(showsIndicators: false) {
                            if segments.isEmpty {
                                Text(resource.content?.isEmpty == false ? resource.content! : "No transcript available.")
                                    .font(theme.typography.bodyMedium)
                                    .foregroundColor(theme.colors.textPrimary)
                                    .lineSpacing(6)
                                    .padding(.horizontal, theme.spacing.lg)
                                    .padding(.bottom, theme.spacing.xl)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                highlightedTranscript
                                    .font(theme.typography.headingMedium)
                                    .fontWeight(.medium)
                                    .lineSpacing(8)
                                    .padding(.horizontal, theme.spacing.lg)
                                    .padding(.bottom, theme.spacing.xl)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl))
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.lg)
                }
            }
        }
        .onAppear(perform: setupAudioPlayer)
        .onDisappear {
            audioPlayer?.stop()
            stopTimer()
        }
    }
    
    // Chooses the latest transcript segment whose timestamp is behind the current playback time.
    private var highlightedTranscript: Text {
        let activeIndex = segments.lastIndex(where: { currentTime >= $0.timestamp }) ?? -1
        
        var combinedText = Text("")
        for (index, segment) in segments.enumerated() {
            let isActive = index == activeIndex
            let wordText = Text(segment.text + " ")
                .foregroundColor(isActive ? theme.colors.primary : theme.colors.textSecondary.opacity(0.6))
            combinedText = combinedText + wordText
        }
        return combinedText
    }
    
    // Loads the audio file from Documents and normalizes transcript timestamps saved by the recorder.
    private func setupAudioPlayer() {
        guard let url = getAudioURL(), FileManager.default.fileExists(atPath: url.path) else {
            hasError = true
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Failed to setup audio player: \(error)")
            hasError = true
        }

        if let content = resource.content, let data = content.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode([TranscriptSegment].self, from: data) {
                let allZero = decoded.allSatisfy { $0.timestamp == 0.0 }
                
                if allZero && !decoded.isEmpty && duration > 0 {
                    let step = duration / Double(decoded.count)
                    segments = decoded.enumerated().map { index, segment in
                        var newSegment = segment
                        newSegment.timestamp = Double(index) * step
                        return newSegment
                    }
                } else if let firstTimestamp = decoded.first?.timestamp, firstTimestamp > 5.0 {
                    segments = decoded.map { segment in
                        var newSegment = segment
                        newSegment.timestamp = max(0, segment.timestamp - firstTimestamp)
                        return newSegment
                    }
                } else {
                    segments = decoded
                }
            }
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
            stopTimer()
        } else {
            audioPlayer?.play()
            startTimer()
        }
        isPlaying.toggle()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer {
                currentTime = player.currentTime
                if !player.isPlaying {
                    isPlaying = false
                    stopTimer()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Older resources may contain full simulator/device paths, so only the filename is trusted when rebuilding the local URL.
    private func getAudioURL() -> URL? {
        guard let path = resource.localFilePath else { return nil }
        
        if path.starts(with: "file://") || path.contains("var/mobile/Containers") || path.contains("CoreSimulator") {
            let tempUrl = URL(string: path) ?? URL(fileURLWithPath: path)
            let filename = tempUrl.lastPathComponent
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(filename)
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(path)
        }
    }
}
