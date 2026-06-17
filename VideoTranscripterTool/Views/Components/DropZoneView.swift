import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Zone (Empty State)

/// Full-size drop target shown when no video is selected and the queue is empty.
/// Encourages users to drag & drop video files directly into the app.
struct DropZoneView: View {
    @EnvironmentObject private var viewModel: TranscriptionViewModel
    @State private var isTargeted = false
    @State private var animateArrow = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isTargeted ? Color.accentColor.opacity(0.05) : .clear)
                )
                .animation(.easeInOut(duration: 0.2), value: isTargeted)

            // Content
            VStack(spacing: 16) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                    .offset(y: animateArrow ? 4 : -4)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: animateArrow
                    )

                VStack(spacing: 6) {
                    Text("Drop Videos Here")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(isTargeted ? .primary : .secondary)

                    Text("Or click **Add Videos** in the toolbar")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                // Supported formats
                HStack(spacing: 6) {
                    ForEach(["MP4", "MOV", "MKV", "AVI"], id: \.self) { ext in
                        Text(ext)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .onAppear { animateArrow = true }
    }

    // MARK: - Drop Handler

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
