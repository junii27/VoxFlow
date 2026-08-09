import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            if !appState.allPermissionsGranted {
                OnboardingView()
            } else {
                mainContent
            }
        }
        .frame(width: 340)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
            Divider()
            statusCard.padding(.horizontal, 16).padding(.vertical, 12)
            Divider()
            historySection
            Divider()
            footer.padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("VoxFlow")
                .font(.system(size: 15, weight: .bold, design: .rounded))

            Spacer()

            SettingsLink {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(statusColor).frame(width: 8, height: 8)
                Text(statusText).font(.system(size: 13, weight: .medium))
                Spacer()

                if appState.isAppleIntelligenceAvailable {
                    Label("AI", systemImage: "brain.head.profile")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.purple.opacity(0.15), in: Capsule())
                        .foregroundStyle(.purple)
                }
            }

            VStack(spacing: 4) {
                Text("Hotkeys:")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text("Double-tap Fn   or   ⌥ Space")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                if !appState.transcriptionHistory.isEmpty {
                    Button("Clear") { appState.clearHistory() }
                        .font(.system(size: 11))
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.top, 10)

            if appState.transcriptionHistory.isEmpty {
                Text("No transcriptions yet")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(appState.transcriptionHistory.prefix(5)) { entry in
                            historyRow(entry)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(.bottom, 8)
    }

    private func historyRow(_ entry: TranscriptionEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.cleanedTranscript)
                .font(.system(size: 12))
                .lineLimit(2)
            HStack(spacing: 6) {
                Text(entry.relativeTimestamp)
                if let app = entry.targetApp { Text("·"); Text(app) }
                Text("·"); Text(entry.formattedDuration)
            }
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(entry.cleanedTranscript, forType: .string)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Quit VoxFlow") { NSApplication.shared.terminate(nil) }
                .font(.system(size: 12)).buttonStyle(.plain).foregroundStyle(.secondary)
            Spacer()
            Text("v1.0").font(.system(size: 10)).foregroundStyle(.quaternary)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch appState.dictationState {
        case .idle: .green
        case .listening: .red
        case .processing: .purple
        case .done: .green
        case .error: .orange
        }
    }

    private var statusText: String {
        switch appState.dictationState {
        case .idle: "Ready"
        case .listening: "Listening..."
        case .processing: "Processing..."
        case .done: "Done"
        case .error(let msg): "Error: \(msg)"
        }
    }
}
