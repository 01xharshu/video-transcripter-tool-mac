import Foundation

// MARK: - Transcription Status

enum TranscriptionStatus: String, Codable, Equatable {
    case pending
    case extractingAudio
    case transcribing
    case completed
    case failed

    var displayName: String {
        switch self {
        case .pending:          return "Pending"
        case .extractingAudio:  return "Extracting Audio"
        case .transcribing:     return "Transcribing"
        case .completed:        return "Completed"
        case .failed:           return "Failed"
        }
    }

    var systemImage: String {
        switch self {
        case .pending:          return "clock"
        case .extractingAudio:  return "waveform.path"
        case .transcribing:     return "text.bubble"
        case .completed:        return "checkmark.circle.fill"
        case .failed:           return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Video Item

struct VideoItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let fileName: String
    let duration: TimeInterval
    var status: TranscriptionStatus
    var progress: Double
    var transcript: String?
    var segments: [TranscriptSegment]
    var detectedLanguages: [String]
    var error: String?

    init(
        url: URL,
        fileName: String,
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.url = url
        self.fileName = fileName
        self.duration = duration
        self.status = .pending
        self.progress = 0.0
        self.transcript = nil
        self.segments = []
        self.detectedLanguages = []
        self.error = nil
    }

    /// Formatted duration string (e.g. "3:45" or "1:02:30")
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func == (lhs: VideoItem, rhs: VideoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Transcript Segment

struct TranscriptSegment: Identifiable, Equatable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
    let language: String?

    init(startTime: TimeInterval, endTime: TimeInterval, text: String, language: String? = nil) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.language = language
    }

    /// Formatted timestamp (e.g. "01:23")
    var formattedTimestamp: String {
        let totalSeconds = Int(startTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
