import WhisperKit
import Foundation

Task {
    do {
        let url = try await WhisperKit.download(variant: "openai_whisper-small", progressCallback: { progress in
            print(progress.fractionCompleted)
        })
        print("URL:", url.path)
    } catch {
        print("Error:", error)
    }
}
