import Foundation
import AVFoundation

// MARK: - Audio Extractor

/// Extracts audio tracks from video files using AVFoundation.
/// Produces a temporary M4A file suitable for transcription.
final class AudioExtractor {

    /// Video container formats the app accepts
    static let supportedExtensions: Set<String> = [
        "mp4", "mov", "m4v", "mkv", "avi", "webm", "wmv", "flv", "ts", "mts"
    ]

    /// Check whether a URL points to a supported video file
    static func isSupported(url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Read the duration of a video asset asynchronously
    static func getVideoDuration(url: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    /// Extract the audio track from a video into a temp M4A file.
    ///
    /// - Parameters:
    ///   - videoURL: Path to the source video.
    ///   - progress: Callback receiving values 0.0–1.0 during export.
    /// - Returns: URL to the temporary audio file. Caller must clean up.
    static func extractAudio(
        from videoURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let asset = AVAsset(url: videoURL)

        // Verify the file has an audio track
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw AudioExtractorError.noAudioTrack
        }

        // Prepare temp output path
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw AudioExtractorError.exportSessionCreationFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        // Poll export progress on a background task
        let progressTask = Task.detached {
            while !Task.isCancelled {
                let currentProgress = Double(exportSession.progress)
                progress(currentProgress)
                try await Task.sleep(nanoseconds: 150_000_000) // 150ms
            }
        }

        // Run export
        await exportSession.export()
        progressTask.cancel()

        // Final progress
        progress(1.0)

        guard exportSession.status == .completed else {
            if let error = exportSession.error {
                throw error
            }
            throw AudioExtractorError.exportFailed
        }

        return outputURL
    }

    /// Remove a temporary audio file
    static func cleanup(audioURL: URL) {
        try? FileManager.default.removeItem(at: audioURL)
    }
}

// MARK: - Errors

enum AudioExtractorError: LocalizedError {
    case exportSessionCreationFailed
    case exportFailed
    case noAudioTrack
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .exportSessionCreationFailed:
            return "Could not create an audio export session. The video codec may not be supported."
        case .exportFailed:
            return "Audio extraction failed unexpectedly."
        case .noAudioTrack:
            return "The selected video file does not contain an audio track."
        case .unsupportedFormat:
            return "This video format is not supported."
        }
    }
}
