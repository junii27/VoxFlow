import SwiftUI
import ServiceManagement
import FoundationModels

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GeneralTab()
                .environment(appState)
                .tabItem { Label("General", systemImage: "gearshape") }

            LanguageTab()
                .environment(appState)
                .tabItem { Label("Language", systemImage: "globe") }

            AITab()
                .environment(appState)
                .tabItem { Label("AI Cleanup", systemImage: "brain.head.profile") }

            PermissionsTab()
                .environment(appState)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Form {
            Toggle("Launch at Login", isOn: $state.launchAtLogin)
                .onChange(of: state.launchAtLogin) { _, enabled in
                    if enabled {
                        try? SMAppService.mainApp.register()
                    } else {
                        try? SMAppService.mainApp.unregister()
                    }
                }

            Toggle("Show Floating HUD", isOn: $state.showHUD)

            LabeledContent("Hotkey") {
                Text("Double-tap Fn")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Language

private struct LanguageTab: View {
    @Environment(AppState.self) private var appState

    private let locales: [(id: String, name: String)] = [
        ("en-US", "English (US)"),
        ("en-GB", "English (UK)"),
        ("es-ES", "Spanish"),
        ("fr-FR", "French"),
        ("de-DE", "German"),
        ("it-IT", "Italian"),
        ("pt-BR", "Portuguese (Brazil)"),
        ("ja-JP", "Japanese"),
        ("ko-KR", "Korean"),
        ("zh-CN", "Chinese (Simplified)"),
    ]

    var body: some View {
        @Bindable var state = appState
        Form {
            Picker("Recognition Language", selection: $state.selectedLanguage) {
                ForEach(locales, id: \.id) { locale in
                    Text(locale.name).tag(locale.id)
                }
            }

            Text("On-device recognition availability varies by language and device.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

// MARK: - AI

private struct AITab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Form {
            Toggle("Enable AI Text Cleanup", isOn: $state.isLLMCleanupEnabled)

            LabeledContent("Apple Intelligence") {
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isAppleIntelligenceAvailable ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(appState.isAppleIntelligenceAvailable ? "Available" : "Not Available")
                        .foregroundStyle(.secondary)
                }
            }

            if !appState.isAppleIntelligenceAvailable {
                Text("Enable Apple Intelligence in System Settings → Apple Intelligence & Siri. Requires Apple Silicon Mac with macOS 26+.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Permissions

private struct PermissionsTab: View {
    @Environment(AppState.self) private var appState
    private let permissions = PermissionsManager()

    var body: some View {
        Form {
            statusRow("Microphone", granted: appState.hasMicrophonePermission)
            statusRow("Speech Recognition", granted: appState.hasSpeechPermission)
            statusRow("Accessibility", granted: appState.hasAccessibilityPermission)

            Button("Refresh Permissions") {
                Task { await permissions.checkAllPermissions(updating: appState) }
            }
        }
        .formStyle(.grouped)
    }

    private func statusRow(_ name: String, granted: Bool) -> some View {
        LabeledContent(name) {
            HStack(spacing: 6) {
                Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(granted ? .green : .red)
                Text(granted ? "Granted" : "Not Granted")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
