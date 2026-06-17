import SwiftUI

// MARK: - Export Sheet

struct ExportView: View {
    @EnvironmentObject private var viewModel: TranscriptionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Options
            optionsForm

            Divider()

            // Actions
            actionBar
        }
        .frame(width: 420)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.accentColor)

            Text("Export Transcriptions")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(viewModel.project.completedCount) video\(viewModel.project.completedCount == 1 ? "" : "s") ready for export")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Options Form

    private var optionsForm: some View {
        Form {
            // Format picker
            Picker("Format", selection: $viewModel.exportOptions.format) {
                ForEach(DocumentExporter.ExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)

            // Toggle options
            Toggle("Include file names as headers", isOn: $viewModel.exportOptions.includeFileHeaders)

            Toggle("Include timestamps", isOn: $viewModel.exportOptions.includeTimestamps)

            // Preview of what will be exported
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Output Preview", systemImage: "doc.text.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    previewText
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(6)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.quaternary)
                        )
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
    }

    private var previewText: some View {
        let lines: [String] = {
            var result: [String] = []
            if viewModel.exportOptions.includeFileHeaders {
                result.append("1. example_video.mp4")
                result.append("Duration: 5:30")
                result.append("───────────────────")
            }
            if viewModel.exportOptions.includeTimestamps {
                result.append("[00:01]  Hello, this is a sample…")
                result.append("[00:15]  यह एक उदाहरण है…")
            } else {
                result.append("Hello, this is a sample transcript…")
                result.append("यह एक उदाहरण है जो दिखाता है…")
            }
            return result
        }()

        return Text(lines.joined(separator: "\n"))
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button {
                viewModel.exportDocument()
                dismiss()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }
}
