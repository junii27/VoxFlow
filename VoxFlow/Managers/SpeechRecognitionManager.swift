import Speech

@MainActor
class SpeechRecognitionManager {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    init(locale: String = "en-US") {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
    }

    func updateLocale(_ localeIdentifier: String) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }

    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }

    var supportsOnDevice: Bool {
        speechRecognizer?.supportsOnDeviceRecognition ?? false
    }

    /// Creates and stores the recognition request. Feed audio buffers to it via AudioCaptureManager.
    func createRecognitionRequest() -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.taskHint = .dictation
        recognitionRequest = request
        return request
    }

    /// Begins the recognition task. Partial results stream via onPartialResult, final via onFinalResult.
    func startRecognition() {
        guard let speechRecognizer, speechRecognizer.isAvailable,
              let request = recognitionRequest else {
            onError?(SpeechError.recognizerUnavailable)
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    let code = (error as NSError).code
                    // Ignore code 216 (cancelled), 1110 (no speech), 203 (no speech detected)
                    if code != 216 && code != 1110 && code != 203 {
                        self.onError?(error)
                    }
                    return
                }

                guard let result else { return }
                let transcript = result.bestTranscription.formattedString

                if result.isFinal {
                    self.onFinalResult?(transcript)
                } else {
                    self.onPartialResult?(transcript)
                }
            }
        }
    }

    func stopRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    enum SpeechError: LocalizedError {
        case recognizerUnavailable
        case onDeviceNotSupported

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable: "Speech recognizer is not available."
            case .onDeviceNotSupported: "On-device recognition not supported for this language."
            }
        }
    }
}
