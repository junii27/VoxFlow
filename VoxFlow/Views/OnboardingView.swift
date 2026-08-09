import SwiftUI
import Speech

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    private let permissions = PermissionsManager()

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text("Welcome to VoxFlow")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text("Grant permissions to get started")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            Divider()

            // Permission rows
            VStack(spacing: 12) {
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    desc: "Capture your voice for dictation",
                    granted: appState.hasMicrophonePermission
                ) {
                    appState.hasMicrophonePermission = await permissions.requestMicrophonePermission()
                }

                permissionRow(
                    icon: "waveform.badge.magnifyingglass",
                    title: "Speech Recognition",
                    desc: "On-device transcription of your voice",
                    granted: appState.hasSpeechPermission
                ) {
                    let status = await permissions.requestSpeechPermission()
                    appState.hasSpeechPermission = (status == .authorized)
                }

                permissionRow(
                    icon: "hand.raised.fill",
                    title: "Accessibility",
                    desc: "Detect hotkey & paste text into apps",
                    granted: appState.hasAccessibilityPermission
                ) {
                    permissions.openAccessibilitySettings()
                }
            }

            Divider()

            // Apple Intelligence status
            HStack(spacing: 10) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 14))
                    .foregroundStyle(appState.isAppleIntelligenceAvailable ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Intelligence")
                        .font(.system(size: 12, weight: .semibold))
                    Text(appState.isAppleIntelligenceAvailable
                         ? "Available — AI text cleanup enabled"
                         : "Not available — basic cleanup will be used")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

            // Refresh button
            Button {
                Task { await permissions.checkAllPermissions(updating: appState) }
            } label: {
                Label("Refresh Status", systemImage: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(20)
        .frame(width: 340)
    }

    private func permissionRow(
        icon: String, title: String, desc: String,
        granted: Bool, action: @escaping () async -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 28, height: 28)
                .background(
                    (granted ? Color.green : Color.orange).opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .foregroundStyle(granted ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(desc).font(.system(size: 11)).foregroundStyle(.secondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Button("Grant") { Task { await action() } }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
