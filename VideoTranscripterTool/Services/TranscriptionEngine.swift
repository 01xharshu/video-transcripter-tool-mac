import Foundation
import WhisperKit

// MARK: - Transcription Engine

/// Wraps WhisperKit to provide on-device, multilingual speech-to-text.
/// Manages model lifecycle (download → ready → transcribe) and exposes
/// observable state for the UI.
@MainActor
final class TranscriptionEngine: ObservableObject {

    static let shared = TranscriptionEngine()

    // MARK: Published State

    /// Whether the Whisper model is loaded and ready
    @Published var isModelReady = false

    /// Whether the model is currently being downloaded / initialised
    @Published var isSettingUp = false

    /// Human-readable setup status for the UI
    @Published var setupStatusMessage = ""

    /// Name of the loaded model
    @Published var modelInfo = ""

    /// Progress of the model download (0.0 to 1.0)
    @Published var downloadProgress: Double = 0.0

    // MARK: Private

    private var whisperKit: WhisperKit?

    private init() {}

    // MARK: - Model Lifecycle

    /// Download and initialize the Whisper model, or load from a local folder.
    func setup(modelFolder: URL? = nil) async {
        guard !isModelReady, !isSettingUp else { return }

        isSettingUp = true
        setupStatusMessage = modelFolder == nil ? "Downloading multilingual AI model…" : "Loading local AI model…"
        downloadProgress = 0.0

        do {
            let finalModelFolder: URL
            let variant = UserDefaults.standard.string(forKey: "whisperModelVariant") ?? "openai_whisper-small"
            if let folder = modelFolder {
                finalModelFolder = folder
            } else {
                finalModelFolder = try await WhisperKit.download(variant: variant) { progress in
                    Task { @MainActor in
                        self.downloadProgress = progress.fractionCompleted
                    }
                }
            }
            
            let pipe = try await WhisperKit(modelFolder: finalModelFolder.path)
            whisperKit = pipe
            isModelReady = true
            modelInfo = "Whisper \(variant.components(separatedBy: "-").last?.capitalized ?? "Model") · Multilingual"
            setupStatusMessage = "Ready"
        } catch {
            setupStatusMessage = "Setup failed: \(error.localizedDescription)"
        }

        isSettingUp = false
    }

    /// Automatically detects if the model is already downloaded locally.
    func detectModel() async {
        guard !isModelReady, !isSettingUp else { return }
        
        do {
            let variant = UserDefaults.standard.string(forKey: "whisperModelVariant") ?? "openai_whisper-small"
            // Attempt to load the model from cache without downloading
            let pipe = try await WhisperKit(model: variant, download: false)
            whisperKit = pipe
            isModelReady = true
            modelInfo = "Whisper \(variant.components(separatedBy: "-").last?.capitalized ?? "Model") · Multilingual"
            setupStatusMessage = "Ready"
        } catch {
            // Model not found locally, UI will show the download options
            setupStatusMessage = ""
        }
    }

    // MARK: - Transcription

    /// Transcribe an audio file and return structured output.
    ///
    /// WhisperKit handles multilingual audio natively — it will detect language
    /// switches within the same audio and transcribe Hindi in Devanagari and
    /// English in Latin script automatically.
    ///
    /// - Parameter audioPath: Absolute path to an audio file (M4A, WAV, etc.)
    /// - Returns: `TranscriptionOutput` with full text and timestamped segments.
    func transcribe(audioPath: String) async throws -> TranscriptionOutput {
        guard let whisperKit else {
            throw TranscriptionEngineError.modelNotReady
        }

        // WhisperKit's transcribe returns [TranscriptionResult]
        // Each result contains text and time-stamped segments.
        let results = try await whisperKit.transcribe(audioPath: audioPath)

        guard !results.isEmpty else {
            throw TranscriptionEngineError.transcriptionFailed
        }

        // Combine text from all result chunks
        let fullText = results.map { $0.text }.joined(separator: " ")

        // Extract segments with timestamps
        var segments: [TranscriptSegment] = []
        for result in results {
            for seg in result.segments {
                let trimmedText = seg.text.trimmingCharacters(in: CharacterSet.whitespaces)
                if !trimmedText.isEmpty {
                    let segment = TranscriptSegment(
                        startTime: TimeInterval(seg.start),
                        endTime: TimeInterval(seg.end),
                        text: trimmedText
                    )
                    segments.append(segment)
                }
            }
        }

        return TranscriptionOutput(
            text: fullText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            segments: segments
        )
    }
}

// MARK: - Output & Errors

struct TranscriptionOutput {
    let text: String
    let segments: [TranscriptSegment]
}

enum TranscriptionEngineError: LocalizedError {
    case modelNotReady
    case transcriptionFailed

    var errorDescription: String? {
        switch self {
        case .modelNotReady:
            return "The transcription model is not ready. Please wait for it to finish downloading."
        case .transcriptionFailed:
            return "Transcription produced no results. The audio may be silent or corrupted."
        }
    }
}
