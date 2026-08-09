import Foundation

struct TranscriptionEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let rawTranscript: String
    let cleanedTranscript: String
    let durationSeconds: Double
    let targetApp: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        rawTranscript: String,
        cleanedTranscript: String,
        durationSeconds: Double,
        targetApp: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.rawTranscript = rawTranscript
        self.cleanedTranscript = cleanedTranscript
        self.durationSeconds = durationSeconds
        self.targetApp = targetApp
    }

    var formattedDuration: String {
        String(format: "%.1fs", durationSeconds)
    }

    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
