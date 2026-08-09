import SwiftUI

struct DictationHUDContentView: View {
    let state: DictationState
    let transcript: String
    let audioLevels: [Float]

    var body: some View {
        HStack(spacing: 14) {
            statusIcon

            Group {
                switch state {
                case .listening:
                    HStack(spacing: 12) {
                        WaveformView(levels: audioLevels)
                        LiveTranscriptView(text: transcript)
                    }

                case .processing:
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                        Text("Cleaning up...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                case .done:
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 16))
                        Text("Pasted!")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                case .error(let message):
                    Text(message)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)

                case .idle:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(width: VFConstants.hudWidth, height: VFConstants.hudHeight)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .listening:
            Image(systemName: "mic.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.red)
                .symbolEffect(.pulse, isActive: true)
        case .processing:
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.purple)
                .symbolEffect(.pulse, isActive: true)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.orange)
        case .idle:
            EmptyView()
        }
    }
}
