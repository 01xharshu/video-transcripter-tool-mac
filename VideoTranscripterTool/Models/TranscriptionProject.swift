import Foundation

// MARK: - Transcription Project

struct TranscriptionProject: Identifiable {
    let id: UUID
    var name: String
    let createdAt: Date
    var videos: [VideoItem]

    init(name: String = "New Project") {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.videos = []
    }

    // MARK: - Computed Properties

    /// All completed transcripts joined with separators
    var compiledTranscript: String {
        videos
            .filter { $0.status == .completed }
            .compactMap { $0.transcript }
            .joined(separator: "\n\n")
    }

    /// Number of completed videos
    var completedCount: Int {
        videos.filter { $0.status == .completed }.count
    }

    /// Number of pending or failed videos that can be (re)transcribed
    var pendingCount: Int {
        videos.filter { $0.status == .pending || $0.status == .failed }.count
    }

    /// Number of videos currently being processed
    var processingCount: Int {
        videos.filter { $0.status == .extractingAudio || $0.status == .transcribing }.count
    }

    /// Total number of videos
    var totalCount: Int {
        videos.count
    }

    /// Whether there are any videos ready for transcription
    var hasTranscribableVideos: Bool {
        pendingCount > 0
    }

    /// Whether all videos have been processed (completed or failed)
    var isFullyProcessed: Bool {
        !videos.isEmpty && pendingCount == 0 && processingCount == 0
    }

    /// Overall progress across all videos (0.0–1.0)
    var overallProgress: Double {
        guard !videos.isEmpty else { return 0 }
        let total = videos.reduce(0.0) { $0 + $1.progress }
        return total / Double(videos.count)
    }
}
