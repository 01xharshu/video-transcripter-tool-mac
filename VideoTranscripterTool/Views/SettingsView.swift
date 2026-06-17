import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, advanced
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            
            ModelSettingsView()
                .tabItem {
                    Label("AI Models", systemImage: "cpu")
                }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 400, height: 250)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("defaultExportFormat") private var defaultExportFormat: String = "docx"
    @AppStorage("autoPlaySound") private var autoPlaySound: Bool = true
    
    var body: some View {
        Form {
            Picker("Default Export Format:", selection: $defaultExportFormat) {
                Text("Word Document (.docx)").tag("docx")
                Text("Plain Text (.txt)").tag("txt")
            }
            .pickerStyle(.menu)
            
            Toggle("Play sound when transcription finishes", isOn: $autoPlaySound)
        }
        .padding()
    }
}

struct ModelSettingsView: View {
    @AppStorage("whisperModelVariant") private var whisperModelVariant: String = "openai_whisper-small"
    
    var body: some View {
        Form {
            Picker("Whisper Model:", selection: $whisperModelVariant) {
                Text("Base (Fastest, Less Accurate)").tag("openai_whisper-base")
                Text("Small (Recommended)").tag("openai_whisper-small")
                Text("Medium (Slower, Highly Accurate)").tag("openai_whisper-medium")
                Text("Large (Slowest, Most Accurate)").tag("openai_whisper-large-v3")
            }
            .pickerStyle(.menu)
            
            Text("Note: Changing the model will require an additional download the next time you start a transcription.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
