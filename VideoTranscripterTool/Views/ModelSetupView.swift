import SwiftUI

// MARK: - Model Setup View (First Launch)

/// Shown on first launch while the AI model is being downloaded.
/// Once the model is ready, the main interface appears automatically.
struct ModelSetupView: View {
    @EnvironmentObject private var engine: TranscriptionEngine
    @State private var animatePulse = false
    @State private var showManualInstructions = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.accentColor.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(animatePulse ? 1.1 : 0.95)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animatePulse
                    )

                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(Color.accentColor)
            }

            // Title
            VStack(spacing: 8) {
                Text("Video Transcripter")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("On-Device Multilingual Transcription")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            // Features
            featuresGrid
                .padding(.top, 24)

            Spacer()

            // Setup section
            setupSection
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .onAppear {
            animatePulse = true
            Task {
                await engine.detectModel()
            }
        }
    }

    // MARK: - Features Grid

    private var featuresGrid: some View {
        HStack(spacing: 24) {
            featureCard(
                icon: "globe",
                title: "Multilingual",
                detail: "Hindi + English\ncode-switching"
            )
            featureCard(
                icon: "lock.shield",
                title: "100% Private",
                detail: "All processing\nstays on device"
            )
            featureCard(
                icon: "bolt.fill",
                title: "Fast",
                detail: "Optimized for\nApple Silicon"
            )
        }
        .padding(.horizontal, 40)
    }

    private func featureCard(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 140, height: 100)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Setup Section

    private var setupSection: some View {
        VStack(spacing: 16) {
            if engine.isSettingUp {
                VStack(spacing: 10) {
                    if engine.downloadProgress > 0 && engine.downloadProgress < 1.0 {
                        ProgressView(value: engine.downloadProgress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 200)
                        
                        Text("\(Int(engine.downloadProgress * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.2)
                    }

                    Text(engine.setupStatusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("This may take a few minutes on first launch")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else if !engine.isModelReady {
                VStack(spacing: 12) {
                    Button {
                        Task { await engine.setup() }
                    } label: {
                        Label("Download AI Model & Get Started", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("~150 MB download · Runs entirely on your Mac")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Button("Manual Download Instructions") {
                        showManualInstructions = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .font(.caption)
                    .padding(.top, 8)

                    if !engine.setupStatusMessage.isEmpty
                        && engine.setupStatusMessage != "Ready" {
                        Text(engine.setupStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showManualInstructions) {
            manualInstructionsView
        }
    }
    
    private var manualInstructionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manual Download Instructions")
                .font(.headline)
            
            Text("If you prefer not to download the model automatically, you can download it from Hugging Face.")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Click the button below to open the Hugging Face repository.")
                Text("2. Download the contents of the `openai_whisper-small` folder.")
                Text("3. Once downloaded, select the folder here:")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            HStack {
                Button("Open Hugging Face in Browser") {
                    if let url = URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-small") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Spacer()
                
                Button("Select Downloaded Folder...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.message = "Select the 'openai_whisper-small' folder"
                    
                    if panel.runModal() == .OK, let url = panel.url {
                        showManualInstructions = false
                        Task {
                            await engine.setup(modelFolder: url)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    showManualInstructions = false
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .controlBackgroundColor).opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
