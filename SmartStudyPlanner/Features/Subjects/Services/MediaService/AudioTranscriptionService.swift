import Foundation
import AVFoundation
import Speech
import Combine
import SwiftUI

// One speech-recognition segment saved with timing so playback can highlight the transcript.
struct TranscriptSegment: Codable, Identifiable, Equatable {
    var id = UUID()
    let text: String
    var timestamp: TimeInterval
    let duration: TimeInterval
}

// Records microphone audio to a local m4a file while using Speech framework partial results for live transcription.
class AudioTranscriptionService: NSObject, ObservableObject {
    
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var transcriptText: String = ""
    @Published var segments: [TranscriptSegment] = []
    @Published var errorMessage: String? = nil
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
//    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var audioFile: AVAudioFile?
    private var timer: Timer?
    var audioFileURL: URL?

    private var recordingStartTime: Date?
    private var manualSegmentTimestamps: [TimeInterval] = []

    override init() {
        super.init()
        setupPermissions()
    }
    
    // Requests microphone and speech permissions early so recording can start without extra setup in the view.
    private func setupPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    // Starts the audio engine, writes buffers to disk, and feeds the same buffers into speech recognition.
    func startRecording() {
        guard !isRecording else { return }

        print("[Transcription] startRecording() called")
        print("[Transcription] Auth status: \(SFSpeechRecognizer.authorizationStatus().rawValue) (0=notDetermined 1=denied 2=restricted 3=authorized)")
        print("[Transcription] speechRecognizer: \(speechRecognizer == nil ? "NIL " : "ok ")")
        if let r = speechRecognizer {
            print("[Transcription] recognizer.isAvailable: \(r.isAvailable)")
            print("[Transcription] recognizer.locale: \(r.locale.identifier)")
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("[Transcription] Audio session activated ")

            let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            audioFileURL = docsDir.appendingPathComponent("\(UUID().uuidString).m4a")
            print("[Transcription] Audio file URL: \(audioFileURL!.path)")

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            print("[Transcription] Recording format: \(recordingFormat)")

            audioFile = try AVAudioFile(forWriting: audioFileURL!, settings: recordingFormat.settings)
            print("[Transcription] AVAudioFile created ")

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                print("[Transcription]  recognitionRequest is nil — aborting")
                return
            }
            recognitionRequest.shouldReportPartialResults = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let error = error {
                    print("[Transcription]  recognitionTask error: \(error) (code: \((error as NSError).code) domain: \((error as NSError).domain))")
                }
                var isFinal = false

                if let result = result {
                    print("[Transcription] Got result — isFinal: \(result.isFinal) text: '\(result.bestTranscription.formattedString)'")
                    let rawSegments = result.bestTranscription.segments
                    let elapsed = self.recordingStartTime.map { Date().timeIntervalSince($0) } ?? TimeInterval(self.elapsedSeconds)

                    // Grow our manual timestamp array for any segments the framework didn't timestamp.
                    while self.manualSegmentTimestamps.count < rawSegments.count {
                        self.manualSegmentTimestamps.append(elapsed)
                    }
                    print("[Transcription] Raw segment timestamps from framework: \(rawSegments.map { $0.timestamp })")

                    let newSegments = rawSegments.enumerated().map { index, segment in
                        let ts = segment.timestamp > 0 ? segment.timestamp : self.manualSegmentTimestamps[index]
                        let dur = segment.duration > 0 ? segment.duration : 0
                        return TranscriptSegment(text: segment.substring, timestamp: ts, duration: dur)
                    }

                    DispatchQueue.main.async {
                        self.transcriptText = result.bestTranscription.formattedString
                        self.segments = newSegments
                    }
                    isFinal = result.isFinal
                }

                if error != nil || isFinal {
                    print("[Transcription] Stopping engine (error: \(error != nil), isFinal: \(isFinal))")
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.audioFile = nil
                }
            }
            print("[Transcription] recognitionTask: \(recognitionTask == nil ? "NIL  — recognizer returned nil task" : "started ")")

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                guard let self = self else { return }
                if !self.isPaused {
                    self.recognitionRequest?.append(buffer)
                    do {
                        try self.audioFile?.write(from: buffer)
                    } catch {
                        print("[Transcription]  Error writing audio buffer: \(error)")
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            print("[Transcription] Audio engine started ")

            isRecording = true
            isPaused = false
            recordingStartTime = Date()
            manualSegmentTimestamps = []
            startTimer()

        } catch {
            print("[Transcription]  Setup failed: \(error)")
            errorMessage = "Failed to setup audio recording: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    func pauseRecording() {
        isPaused.toggle()
        if isPaused {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func stopRecording() {
        print("[Transcription] stopRecording() called — segments saved: \(segments.count)")
        print("[Transcription] transcript at stop: '\(transcriptText)'")
        print("[Transcription] audioFileURL at stop: \(audioFileURL?.path ?? "nil")")
        if let url = audioFileURL {
            let exists = FileManager.default.fileExists(atPath: url.path)
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            print("[Transcription] audio file exists: \(exists), size: \(size) bytes")
        }
        stopTimer()

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        isRecording = false
        isPaused = false
        recordingStartTime = nil
        manualSegmentTimestamps = []
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.elapsedSeconds += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Stores transcript segments as JSON on the recording resource for later synchronized playback.
    func getJSONTranscript() -> String {
        if let data = try? JSONEncoder().encode(segments), let jsonStr = String(data: data, encoding: .utf8) {
            return jsonStr
        }
        return ""
    }
}
