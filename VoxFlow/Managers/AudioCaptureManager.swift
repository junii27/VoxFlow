import AVFoundation
import Speech

@MainActor
class AudioCaptureManager {
    private let audioEngine = AVAudioEngine()
    private(set) var isCapturing = false

    var audioLevelCallback: ((Float) -> Void)?

    func startCapture(feedingTo request: SFSpeechAudioBufferRecognitionRequest) throws {
        guard !isCapturing else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: VFConstants.audioBufferSize, format: recordingFormat) { buffer, _ in
            request.append(buffer)
            let level = AudioCaptureManager.computeAudioLevel(buffer: buffer)
            Task { @MainActor [weak self] in
                self?.audioLevelCallback?(level)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isCapturing = true
    }

    func stopCapture() {
        guard isCapturing else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isCapturing = false
    }

    private static func computeAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }

        var sum: Float = 0
        for i in 0..<frames {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frames))
        return min(1.0, rms * 8.0)
    }

    nonisolated static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { @Sendable granted in
                Task { @MainActor in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
