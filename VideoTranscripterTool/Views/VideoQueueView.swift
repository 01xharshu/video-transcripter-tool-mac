import SwiftUI
import UniformTypeIdentifiers

// MARK: - Video Queue Sidebar

struct VideoQueueView: View {
    @EnvironmentObject private var viewModel: TranscriptionViewModel

    var body: some View {
        Group {
            if viewModel.project.videos.isEmpty {
                emptyState
            } else {
                videoList
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Video List

    private var videoList: some View {
        List(selection: $viewModel.selectedVideoID) {
            Section {
                ForEach(viewModel.project.videos) { video in
                    VideoRowView(video: video)
                        .tag(video.id)
                        .contextMenu {
                            contextMenu(for: video)
                        }
                }
            } header: {
                HStack {
                    Text("Videos")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(viewModel.project.videos.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "film.stack")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("No Videos")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Drop videos here or click\n\"Add Videos\" in the toolbar")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if viewModel.project.totalCount > 0 {
                Button(role: .destructive) {
                    viewModel.removeAllVideos()
                } label: {
                    Label("Clear All", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Remove all videos")
            }

            Spacer()

            if viewModel.isProcessing {
                HStack(spacing: 4) {
                    ProgressView(value: viewModel.project.overallProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 60)

                    Text("\(Int(viewModel.project.overallProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for video: VideoItem) -> some View {
        if video.status == .failed {
            Button {
                viewModel.retryVideo(video)
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }

        Button(role: .destructive) {
            viewModel.removeVideo(video)
        } label: {
            Label("Remove", systemImage: "trash")
        }
    }

    // MARK: - Drag & Drop

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []

        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                defer { group.leave() }
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                if AudioExtractor.isSupported(url: url) {
                    urls.append(url)
                }
            }
        }

        group.notify(queue: .main) {
            viewModel.addVideosFromDrop(urls: urls)
        }

        return true
    }
}

// MARK: - Video Row

struct VideoRowView: View {
    let video: VideoItem

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail / icon
            videoIcon

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(video.fileName)
                    .font(.system(.body, design: .default, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Text(video.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    StatusBadge(status: video.status)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            // Progress bar for in-progress items
            if video.status == .extractingAudio || video.status == .transcribing {
                ProgressView(value: video.progress)
                    .progressViewStyle(.linear)
                    .tint(video.status == .extractingAudio ? .orange : .accentColor)
                    .scaleEffect(y: 0.5)
                    .offset(y: 6)
            }
        }
    }

    private var videoIcon: some View {
        Image(systemName: "film")
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.quaternary)
            )
    }
}
