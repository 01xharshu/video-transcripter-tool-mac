import SwiftUI

// MARK: - Content View (Main Layout)

struct ContentView: View {
    @EnvironmentObject private var engine: TranscriptionEngine
    @StateObject private var viewModel = TranscriptionViewModel()

    var body: some View {
        Group {
            if engine.isModelReady {
                mainInterface
            } else {
                ModelSetupView()
            }
        }
        .environmentObject(viewModel)
    }

    // MARK: - Main Interface

    private var mainInterface: some View {
        NavigationSplitView {
            VideoQueueView()
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 380)
        } detail: {
            detailContent
        }
        .toolbar { mainToolbar }
        .sheet(isPresented: $viewModel.showExportSheet) {
            ExportView()
                .environmentObject(viewModel)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        if viewModel.selectedVideo != nil {
            TranscriptPreviewView()
        } else if viewModel.project.videos.isEmpty {
            DropZoneView()
        } else {
            emptySelectionView
        }
    }

    private var emptySelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(.tertiary)
            Text("Select a video to view its transcript")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var mainToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            addVideosButton
            Divider()
            transcribeButton
            exportButton
        }

        ToolbarItem(placement: .status) {
            statusIndicator
        }
    }

    private var addVideosButton: some View {
        Button {
            viewModel.addVideos()
        } label: {
            Label("Add Videos", systemImage: "plus.circle.fill")
        }
        .help("Add video files to transcribe")
    }

    @ViewBuilder
    private var transcribeButton: some View {
        if viewModel.isProcessing {
            Button {
                viewModel.cancelTranscription()
            } label: {
                Label("Stop", systemImage: "stop.circle.fill")
                    .foregroundStyle(.red)
            }
            .help("Cancel transcription")
        } else {
            Button {
                viewModel.startTranscription()
            } label: {
                Label("Transcribe All", systemImage: "waveform.badge.plus")
            }
            .disabled(viewModel.project.videos.isEmpty || !viewModel.project.hasTranscribableVideos)
            .help("Transcribe all pending videos")
        }
    }

    private var exportButton: some View {
        Button {
            viewModel.showExportSheet = true
        } label: {
            Label("Export", systemImage: "square.and.arrow.up.fill")
        }
        .disabled(!viewModel.hasCompletedTranscripts)
        .help("Export transcriptions to a document")
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if viewModel.isProcessing {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Transcribing…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if viewModel.project.totalCount > 0 {
            Text("\(viewModel.project.completedCount)/\(viewModel.project.totalCount) completed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
