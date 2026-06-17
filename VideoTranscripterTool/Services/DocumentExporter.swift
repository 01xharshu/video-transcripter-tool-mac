import Foundation
import AppKit

// MARK: - Document Exporter

/// Compiles transcripts from multiple videos into a single DOCX or TXT file.
final class DocumentExporter {

    // MARK: - Export Options

    struct ExportOptions {
        var includeTimestamps: Bool = false
        var includeFileHeaders: Bool = true
        var format: ExportFormat = .docx
    }

    enum ExportFormat: String, CaseIterable, Identifiable {
        case docx = "docx"
        case txt = "txt"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .docx: return "Word Document (.docx)"
            case .txt:  return "Plain Text (.txt)"
            }
        }

        var fileExtension: String { rawValue }
    }

    // MARK: - Public API

    /// Export the completed transcripts to the given URL.
    static func export(
        videos: [VideoItem],
        options: ExportOptions,
        to url: URL
    ) throws {
        switch options.format {
        case .docx: try exportDOCX(videos: videos, options: options, to: url)
        case .txt:  try exportTXT(videos: videos, options: options, to: url)
        }
    }

    // MARK: - DOCX Export

    private static func exportDOCX(
        videos: [VideoItem],
        options: ExportOptions,
        to url: URL
    ) throws {
        let doc = NSMutableAttributedString()
        let completedVideos = videos.filter { $0.status == .completed && $0.transcript != nil }

        // — Title —
        doc.append(styled(
            "Video Transcriptions\n",
            font: .systemFont(ofSize: 26, weight: .bold),
            color: .labelColor
        ))

        // — Subtitle / date —
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
        doc.append(styled(
            "Generated: \(dateString)\n",
            font: .systemFont(ofSize: 11, weight: .regular),
            color: .secondaryLabelColor
        ))
        doc.append(styled(
            "Videos: \(completedVideos.count)\n\n",
            font: .systemFont(ofSize: 11, weight: .regular),
            color: .secondaryLabelColor
        ))

        // — Per-video sections —
        for (index, video) in completedVideos.enumerated() {
            // Divider
            doc.append(styled(
                "\n" + String(repeating: "─", count: 60) + "\n\n",
                font: .systemFont(ofSize: 10),
                color: .separatorColor
            ))

            // Header
            if options.includeFileHeaders {
                doc.append(styled(
                    "\(index + 1). \(video.fileName)\n",
                    font: .systemFont(ofSize: 18, weight: .semibold),
                    color: .labelColor
                ))
                doc.append(styled(
                    "Duration: \(video.formattedDuration)\n\n",
                    font: .systemFont(ofSize: 11, weight: .regular),
                    color: .tertiaryLabelColor
                ))
            }

            // Body — timestamped or plain
            if options.includeTimestamps && !video.segments.isEmpty {
                for segment in video.segments {
                    doc.append(styled(
                        "[\(segment.formattedTimestamp)]  ",
                        font: .monospacedSystemFont(ofSize: 11, weight: .regular),
                        color: .secondaryLabelColor
                    ))
                    doc.append(styled(
                        "\(segment.text)\n",
                        font: .systemFont(ofSize: 13, weight: .regular),
                        color: .labelColor
                    ))
                }
            } else if let transcript = video.transcript {
                doc.append(styled(
                    transcript + "\n",
                    font: .systemFont(ofSize: 13, weight: .regular),
                    color: .labelColor
                ))
            }
        }

        // Write DOCX via native macOS API
        let range = NSRange(location: 0, length: doc.length)
        let attrs: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.officeOpenXML
        ]
        let data = try doc.data(from: range, documentAttributes: attrs)
        try data.write(to: url)
    }

    // MARK: - TXT Export

    private static func exportTXT(
        videos: [VideoItem],
        options: ExportOptions,
        to url: URL
    ) throws {
        var lines: [String] = []
        let completedVideos = videos.filter { $0.status == .completed && $0.transcript != nil }

        lines.append("VIDEO TRANSCRIPTIONS")
        lines.append("Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))")
        lines.append("Videos: \(completedVideos.count)")
        lines.append(String(repeating: "=", count: 60))
        lines.append("")

        for (index, video) in completedVideos.enumerated() {
            if options.includeFileHeaders {
                lines.append("\(index + 1). \(video.fileName)")
                lines.append("Duration: \(video.formattedDuration)")
                lines.append(String(repeating: "-", count: 40))
                lines.append("")
            }

            if options.includeTimestamps && !video.segments.isEmpty {
                for segment in video.segments {
                    lines.append("[\(segment.formattedTimestamp)]  \(segment.text)")
                }
            } else if let transcript = video.transcript {
                lines.append(transcript)
            }

            if index < completedVideos.count - 1 {
                lines.append("")
                lines.append(String(repeating: "=", count: 60))
                lines.append("")
            }
        }

        let content = lines.joined(separator: "\n")
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Helpers

    private static func styled(
        _ text: String,
        font: NSFont,
        color: NSColor
    ) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color
        ])
    }
}
