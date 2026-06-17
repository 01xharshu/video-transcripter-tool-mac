import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Transcription ViewModel

/// Central state manager for the app. Handles video queue management,
/// sequential transcription pipeline, and document export.
@MainActor
final class TranscriptionViewModel: ObservableObject {

    // MARK: Published State

    @Published var project = TranscriptionProject()
    @Published var selectedVideoID: UUID?
    @Published var isProcessing = false
    @Published var showExportSheet = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var exportOptions = DocumentExporter.ExportOptions()

    // MARK: Dependencies

    let engine: TranscriptionEngine

    // MARK: Private

    private var transcriptionTask: Task<Void, Never>?

    // MARK: Init

    init(engine: TranscriptionEngine) {
        self.engine = engine
        
        let defaultFormatStr = UserDefaults.standard.string(forKey: "defaultExportFormat") ?? "docx"
        if let format = DocumentExporter.ExportFormat.allCases.first(where: { $0.rawValue == defaultFormatStr }) {
            self.exportOptions.format = format
        }
    }

    convenience init() {
        self.init(engine: TranscriptionEngine.shared)
    }

    // MARK: - Computed Properties

    var selectedVideo: VideoItem? {
        guard let id = selectedVideoID else { return nil }
        return project.videos.first { $0.id == id }
    }

    var hasCompletedTranscripts: Bool {
        project.completedCount > 0
    }

    // MARK: - Video Queue Management

    /// Show an open panel and add selected videos to the queue.
    func addVideos() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .movie, .video, .mpeg4Movie, .quickTimeMovie, .avi
        ]
        panel.message = "Select video files to transcribe"
        panel.prompt = "Add Videos"

        guard panel.runModal() == .OK else { return }

        Task {
            for url in panel.urls {
                await addSingleVideo(url: url)
            }
        }
    }

    /// Add a single video URL to the project.
    func addSingleVideo(url: URL) async {
        // Skip duplicates
        guard !project.videos.contains(where: { $0.url == url }) else { return }

        do {
            let duration = try await AudioExtractor.getVideoDuration(url: url)
            let video = VideoItem(
                url: url,
                fileName: url.lastPathComponent,
                duration: duration
            )
            project.videos.append(video)

            // Auto-select first video
            if selectedVideoID == nil {
                selectedVideoID = video.id
            }
        } catch {
            presentError("Could not add \"\(url.lastPathComponent)\": \(error.localizedDescription)")
        }
    }

    /// Add videos from a drag-and-drop operation.
    func addVideosFromDrop(urls: [URL]) {
        Task {
            for url in urls {
                guard AudioExtractor.isSupported(url: url) else { continue }
                await addSingleVideo(url: url)
            }
        }
    }

    /// Remove a video from the queue.
    func removeVideo(_ video: VideoItem) {
        project.videos.removeAll { $0.id == video.id }
        if selectedVideoID == video.id {
            selectedVideoID = project.videos.first?.id
        }
    }

    /// Clear the entire video queue.
    func removeAllVideos() {
        cancelTranscription()
        project.videos.removeAll()
        selectedVideoID = nil
    }

    // MARK: - Transcription Pipeline

    /// Begin transcribing all pending/failed videos sequentially.
    func startTranscription() {
        guard !isProcessing else { return }
        guard project.hasTranscribableVideos else {
            presentError("No videos to transcribe. Add some videos first.")
            return
        }

        isProcessing = true

        transcriptionTask = Task {
            for index in project.videos.indices {
                let status = project.videos[index].status
                guard status == .pending || status == .failed else { continue }

                if Task.isCancelled { break }
                await processVideo(at: index)
            }
            isProcessing = false
        }
    }

    /// Cancel any in-flight transcription.
    func cancelTranscription() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        isProcessing = false

        // Reset any in-progress items back to pending
        for index in project.videos.indices {
            let status = project.videos[index].status
            if status == .extractingAudio || status == .transcribing {
                project.videos[index].status = .pending
                project.videos[index].progress = 0
            }
        }
    }

    /// Retry a single failed video.
    func retryVideo(_ video: VideoItem) {
        guard let index = project.videos.firstIndex(where: { $0.id == video.id }) else { return }
        project.videos[index].status = .pending
        project.videos[index].progress = 0
        project.videos[index].error = nil

        if !isProcessing {
            startTranscription()
        }
    }

    // MARK: - Internal Pipeline

    private func processVideo(at index: Int) async {
        guard index < project.videos.count else { return }

        // ── Phase 1: Extract audio (0% → 30%) ──
        project.videos[index].status = .extractingAudio
        project.videos[index].progress = 0

        var audioURL: URL?

        do {
            audioURL = try await AudioExtractor.extractAudio(
                from: project.videos[index].url
            ) { [weak self] extractionProgress in
                Task { @MainActor [weak self] in
                    guard let self, index < self.project.videos.count else { return }
                    self.project.videos[index].progress = extractionProgress * 0.3
                }
            }
        } catch {
            project.videos[index].status = .failed
            project.videos[index].error = error.localizedDescription
            return
        }

        guard let audioURL else {
            project.videos[index].status = .failed
            project.videos[index].error = "Audio extraction produced no output."
            return
        }

        defer { AudioExtractor.cleanup(audioURL: audioURL) }

        // ── Phase 2: Transcribe (30% → 100%) ──
        project.videos[index].status = .transcribing
        project.videos[index].progress = 0.3

        do {
            let output = try await engine.transcribe(audioPath: audioURL.path)
            project.videos[index].transcript = output.text
            project.videos[index].segments = output.segments
            project.videos[index].status = .completed
            project.videos[index].progress = 1.0
        } catch {
            project.videos[index].status = .failed
            project.videos[index].error = error.localizedDescription
        }
    }

    // MARK: - Document Export

    /// Show a save panel and export all completed transcripts.
    func exportDocument() {
        let completedVideos = project.videos.filter { $0.status == .completed }
        guard !completedVideos.isEmpty else {
            presentError("No completed transcriptions to export.")
            return
        }

        let panel = NSSavePanel()
        let ext = exportOptions.format.fileExtension
        if let contentType = UTType(filenameExtension: ext) {
            panel.allowedContentTypes = [contentType]
        }
        panel.nameFieldStringValue = "transcriptions.\(ext)"
        panel.message = "Save the compiled transcriptions"
        panel.prompt = "Export"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try DocumentExporter.export(
                videos: project.videos,
                options: exportOptions,
                to: url
            )
        } catch {
            presentError("Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
