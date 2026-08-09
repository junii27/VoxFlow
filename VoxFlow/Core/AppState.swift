import Foundation
import SwiftUI

enum DictationState: Equatable {
    case idle
    case listening
    case processing
    case done(String)
    case error(String)
}

@Observable
@MainActor
class AppState {
    // MARK: - Dictation
    var dictationState: DictationState = .idle
    var currentTranscript: String = ""
    var audioLevel: Float = 0.0
    var audioLevels: [Float] = Array(repeating: 0, count: VFConstants.waveformBarCount)
    var recordingStartTime: Date?

    var isRecording: Bool { dictationState == .listening }
    var isProcessing: Bool { dictationState == .processing }
    var isIdle: Bool { dictationState == .idle }

    // MARK: - Settings
    var selectedLanguage: String = "en-US"
    var isLLMCleanupEnabled: Bool = true
    var showHUD: Bool = true
    var launchAtLogin: Bool = false

    // MARK: - Permissions
    var hasMicrophonePermission: Bool = false
    var hasSpeechPermission: Bool = false
    var hasAccessibilityPermission: Bool = false
    var isAppleIntelligenceAvailable: Bool = false

    var allPermissionsGranted: Bool {
        hasMicrophonePermission && hasSpeechPermission && hasAccessibilityPermission
    }

    // MARK: - History
    var transcriptionHistory: [TranscriptionEntry] = []
    var showDictationHUD: Bool = false

    func addToHistory(_ entry: TranscriptionEntry) {
        transcriptionHistory.insert(entry, at: 0)
        if transcriptionHistory.count > VFConstants.maxHistoryEntries {
            transcriptionHistory.removeLast()
        }
    }

    func clearHistory() {
        transcriptionHistory.removeAll()
    }
}
