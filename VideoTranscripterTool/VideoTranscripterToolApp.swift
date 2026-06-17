import SwiftUI

@main
struct VideoTranscripterToolApp: App {
    @StateObject private var engine = TranscriptionEngine.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .frame(minWidth: 860, minHeight: 540)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1060, height: 700)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
