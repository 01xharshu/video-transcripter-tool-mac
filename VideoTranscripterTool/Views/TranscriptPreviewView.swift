import SwiftUI

// MARK: - Transcript Preview

struct TranscriptPreviewView: View {
    @EnvironmentObject private var viewModel: TranscriptionViewModel
    @State private var showTimestamps = false
    @State private var useMonospacedFont = false
    @State private var copied = false

    private var video: VideoItem? {
        viewModel.selectedVideo
    }

    var body: some View {
        Group {
            if let video {
                videoTranscriptView(video)
            } else {
                Text("Select a video")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Main Transcript View

    private func videoTranscriptView(_ video: VideoItem) -> some View {
        VStack(spacing: 0) {
            // Header
            transcriptHeader(video)

            Divider()

            // Body
            transcriptBody(video)
        }
    }

    // MARK: - Header

    private func transcriptHeader(_ video: VideoItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(video.fileName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(video.formattedDuration, systemImage: "clock")
                    if video.status == .completed, !video.segments.isEmpty {
                        Label("\(video.segments.count) segments", systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Controls
            if video.status == .completed {
                headerControls
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var headerControls: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $showTimestamps) {
                Image(systemName: "clock.badge.checkmark")
            }
            .toggleStyle(.button)
            .help("Show timestamps")

            Toggle(isOn: $useMonospacedFont) {
                Image(systemName: "textformat.abc")
            }
            .toggleStyle(.button)
            .help("Toggle monospaced font")

            Divider()
                .frame(height: 16)

            Button {
                copyTranscript()
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
            }
            .help("Copy transcript to clipboard")
        }
    }

    // MARK: - Body

    @ViewBuilder
    private func transcriptBody(_ video: VideoItem) -> some View {
        switch video.status {
        case .pending:
            placeholderView(
                icon: "clock",
                title: "Waiting to Transcribe",
                subtitle: "Click \"Transcribe All\" to start processing"
            )

        case .extractingAudio:
            progressView(
                title: "Extracting Audio…",
                subtitle: "Separating the audio track from the video",
                progress: video.progress,
                color: .orange
            )

        case .transcribing:
            progressView(
                title: "Transcribing…",
                subtitle: "AI is processing the audio — this may take a moment",
                progress: nil,
                color: .accentColor
            )

        case .completed:
            completedTranscriptView(video)

        case .failed:
            errorView(video)
        }
    }

    // MARK: - Completed Transcript

    private func completedTranscriptView(_ video: VideoItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if showTimestamps && !video.segments.isEmpty {
                    timestampedView(video.segments)
                } else if let transcript = video.transcript {
                    Text(transcript)
                        .font(transcriptFont)
                        .textSelection(.enabled)
                        .lineSpacing(6)
                        .padding(20)
                } else {
                    Text("No transcript available")
                        .foregroundStyle(.secondary)
                        .padding(20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func timestampedView(_ segments: [TranscriptSegment]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(segments) { segment in
                HStack(alignment: .top, spacing: 12) {
                    Text(segment.formattedTimestamp)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .trailing)

                    Text(segment.text)
                        .font(transcriptFont)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - State Views

    private func placeholderView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func progressView(title: String, subtitle: String, progress: Double?, color: Color) -> some View {
        VStack(spacing: 16) {
            Spacer()

            if let progress {
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
                    .tint(color)
                    .scaleEffect(1.5)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(color)
                    .scaleEffect(1.5)
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ video: VideoItem) -> some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            Text("Transcription Failed")
                .font(.title3)
                .fontWeight(.medium)

            if let error = video.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                viewModel.retryVideo(video)
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var transcriptFont: Font {
        useMonospacedFont
            ? .system(.body, design: .monospaced)
            : .system(.body, design: .default)
    }

    private func copyTranscript() {
        guard let text = video?.transcript else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        withAnimation(.easeInOut(duration: 0.2)) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { copied = false }
        }
    }
}
