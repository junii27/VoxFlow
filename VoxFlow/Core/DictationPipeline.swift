import Foundation
import AppKit

@MainActor
class DictationPipeline {
    private let appState: AppState
    private let hotkeyManager = HotkeyManager()
    private let audioCapture = AudioCaptureManager()
    private let speechManager: SpeechRecognitionManager
    private let textCleanup = TextCleanupManager()
    private let textOutput = TextOutputManager()
    private let permissions = PermissionsManager()

    private var hudPanel: DictationHUDPanel?
    private var recordingStart: Date?

    init(appState: AppState) {
        self.appState = appState
        self.speechManager = SpeechRecognitionManager(locale: appState.selectedLanguage)
        setupCallbacks()
    }

    func start() async {
        await permissions.checkAllPermissions(updating: appState)
        if appState.isLLMCleanupEnabled { textCleanup.prewarm() }
        hotkeyManager.startMonitoring()
    }

    func stop() {
        hotkeyManager.stopMonitoring()
        stopDictation()
    }

    // MARK: - Callbacks

    private func setupCallbacks() {
        hotkeyManager.onRecordingStart = { [weak self] in self?.startDictation() }
        hotkeyManager.onRecordingStop  = { [weak self] in self?.stopDictation() }

        audioCapture.audioLevelCallback = { [weak self] level in
            Task { @MainActor in
                guard let self else { return }
                self.appState.audioLevel = level
                self.appState.audioLevels.removeFirst()
                self.appState.audioLevels.append(level)
                self.updateHUD()
                self.handleSilenceDetection(level: level)
            }
        }

        speechManager.onPartialResult = { [weak self] text in
            Task { @MainActor in
                self?.appState.currentTranscript = text
                self?.updateHUD()
            }
        }

        speechManager.onFinalResult = { [weak self] text in
            Task { @MainActor in
                self?.appState.currentTranscript = text
                self?.processFinalTranscript(text)
            }
        }

        speechManager.onError = { [weak self] error in
            Task { @MainActor in
                self?.appState.dictationState = .error(error.localizedDescription)
                self?.updateHUD()
                self?.dismissHUDAfterDelay(2.0)
            }
        }
    }

    func toggleDictation() {
        if appState.isRecording {
            stopDictation()
        } else {
            startDictation()
        }
    }

    // MARK: - Dictation Lifecycle

    private func startDictation() {
        guard appState.isIdle else { return }

        if !appState.allPermissionsGranted {
            Task {
                await permissions.checkAllPermissions(updating: appState)
            }
            return
        }

        speechManager.updateLocale(appState.selectedLanguage)
        appState.currentTranscript = ""
        appState.audioLevels = Array(repeating: 0, count: VFConstants.waveformBarCount)
        appState.dictationState = .listening
        recordingStart = Date()

        if appState.showHUD { showHUD() }

        let request = speechManager.createRecognitionRequest()
        do {
            try audioCapture.startCapture(feedingTo: request)
            speechManager.startRecognition()
        } catch {
            appState.dictationState = .error("Audio capture failed")
            updateHUD()
            dismissHUDAfterDelay(2.0)
        }
    }

    private func stopDictation() {
        guard appState.isRecording else { return }

        audioCapture.stopCapture()
        speechManager.stopRecognition()

        let transcript = appState.currentTranscript
        if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            processFinalTranscript(transcript)
        } else {
            appState.dictationState = .idle
            dismissHUD()
        }
    }

    private func processFinalTranscript(_ rawText: String) {
        appState.dictationState = .processing
        updateHUD()

        let duration = recordingStart.map { Date().timeIntervalSince($0) } ?? 0
        let targetApp = NSWorkspace.shared.frontmostApplicationName

        Task {
            do {
                let cleaned: String
                if appState.isLLMCleanupEnabled {
                    cleaned = try await textCleanup.cleanTranscript(rawText)
                } else {
                    cleaned = rawText
                }

                textOutput.outputText(cleaned)

                appState.addToHistory(TranscriptionEntry(
                    rawTranscript: rawText,
                    cleanedTranscript: cleaned,
                    durationSeconds: duration,
                    targetApp: targetApp
                ))

                appState.dictationState = .done(cleaned)
                updateHUD()
                dismissHUDAfterDelay(VFConstants.hudDoneDisplayDuration)

                let resetDelay = VFConstants.hudDoneDisplayDuration + VFConstants.hudFadeOutDuration
                DispatchQueue.main.asyncAfter(deadline: .now() + resetDelay) {
                    self.appState.dictationState = .idle
                }

            } catch {
                appState.dictationState = .error("Cleanup failed")
                updateHUD()
                dismissHUDAfterDelay(2.0)
            }
        }
    }

    // MARK: - HUD

    private func showHUD() {
        let content = DictationHUDContentView(
            state: appState.dictationState,
            transcript: appState.currentTranscript,
            audioLevels: appState.audioLevels
        )
        let panel = DictationHUDPanel(contentView: content)
        panel.showAtBottomCenter()
        hudPanel = panel
    }

    private func updateHUD() {
        hudPanel?.updateContent(DictationHUDContentView(
            state: appState.dictationState,
            transcript: appState.currentTranscript,
            audioLevels: appState.audioLevels
        ))
    }

    private func dismissHUD() {
        hudPanel?.fadeOut { [weak self] in self?.hudPanel = nil }
    }

    private func dismissHUDAfterDelay(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.dismissHUD()
        }
    }

    // MARK: - Silence Auto-Stop (0.5s Pause)

    private var lastVoiceTime: Date?

    private func handleSilenceDetection(level: Float) {
        guard appState.isRecording,
              !appState.currentTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastVoiceTime = nil
            return
        }

        let isSpeaking = level >= VFConstants.silenceAudioLevelThreshold

        if isSpeaking {
            lastVoiceTime = nil
        } else {
            if lastVoiceTime == nil {
                lastVoiceTime = Date()
            } else if let lastVoice = lastVoiceTime, Date().timeIntervalSince(lastVoice) >= VFConstants.autoStopSilenceThreshold {
                lastVoiceTime = nil
                stopDictation()
            }
        }
    }
}
