import AVFoundation
import Speech
import AppKit
import FoundationModels

@MainActor
class PermissionsManager {

    func checkAllPermissions(updating state: AppState) async {
        state.hasMicrophonePermission = await checkMicrophonePermission()
        state.hasSpeechPermission = await checkSpeechPermission()
        state.hasAccessibilityPermission = TextOutputManager.isAccessibilityGranted
        state.isAppleIntelligenceAvailable = SystemLanguageModel.default.availability == .available
    }

    func requestMicrophonePermission() async -> Bool {
        let granted = await AudioCaptureManager.requestMicrophonePermission()
        if granted {
            return true
        } else {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
            return false
        }
    }

    func requestSpeechPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            return await SpeechRecognitionManager.requestAuthorization()
        } else if status == .denied || status == .restricted {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
                NSWorkspace.shared.open(url)
            }
        }
        return status
    }

    func openAccessibilitySettings() {
        TextOutputManager.promptAccessibility()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Private

    private func checkMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .authorized {
            return true
        } else {
            return await AudioCaptureManager.requestMicrophonePermission()
        }
    }

    private func checkSpeechPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized {
            return true
        } else if status == .notDetermined {
            let result = await SpeechRecognitionManager.requestAuthorization()
            return result == .authorized
        } else {
            return false
        }
    }
}
