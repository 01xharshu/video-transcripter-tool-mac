import WhisperKit
import Foundation

Task {
    do {
        let kit = try await WhisperKit(model: "openai_whisper-small", download: true) { progress in
            print(progress)
        }
    } catch {}
}
