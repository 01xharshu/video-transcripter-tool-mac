import SwiftUI

// MARK: - Status Badge

/// Compact pill showing a video's transcription status with an icon and color.
struct StatusBadge: View {
    let status: TranscriptionStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: status.systemImage)
                .font(.system(size: 8, weight: .bold))

            Text(status.displayName)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.15), in: Capsule())
        .foregroundStyle(foregroundColor)
    }

    private var foregroundColor: Color {
        switch status {
        case .pending:          return .secondary
        case .extractingAudio:  return .orange
        case .transcribing:     return .accentColor
        case .completed:        return .green
        case .failed:           return .red
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .pending:          return .gray
        case .extractingAudio:  return .orange
        case .transcribing:     return .accentColor
        case .completed:        return .green
        case .failed:           return .red
        }
    }
}
