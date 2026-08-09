import AVFoundation

enum VFConstants {
    static let appName = "VoxFlow"

    // Hotkey
    static let doubleTapInterval: TimeInterval = 0.6
    static let minimumRecordingDuration: TimeInterval = 0.3

    // Audio
    static let audioBufferSize: AVAudioFrameCount = 1024
    static let autoStopSilenceThreshold: TimeInterval = 1.5
    static let silenceAudioLevelThreshold: Float = 0.04

    // HUD
    static let hudWidth: CGFloat = 420
    static let hudHeight: CGFloat = 56
    static let hudCornerRadius: CGFloat = 28
    static let hudBottomPadding: CGFloat = 80
    static let hudFadeInDuration: TimeInterval = 0.25
    static let hudFadeOutDuration: TimeInterval = 0.3
    static let hudDoneDisplayDuration: TimeInterval = 0.8

    // Waveform
    static let waveformBarCount = 24

    // Text Output
    static let pasteDelay: TimeInterval = 0.05
    static let clipboardRestoreDelay: TimeInterval = 0.5

    // History
    static let maxHistoryEntries = 50
}
