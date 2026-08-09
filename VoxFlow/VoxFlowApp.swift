import SwiftUI

@main
struct VoxFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appDelegate.appState)
        } label: {
            Image(systemName: appDelegate.appState.isRecording
                  ? "waveform.circle.fill"
                  : (appDelegate.appState.isProcessing
                     ? "brain.head.profile.fill"
                     : "waveform.circle"))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appDelegate.appState)
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var pipeline: DictationPipeline?

    func applicationDidFinishLaunching(_ notification: Notification) {
        pipeline = DictationPipeline(appState: appState)
        Task { await pipeline?.start() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        pipeline?.stop()
    }
}
