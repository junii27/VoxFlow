import Foundation
import FoundationModels

@MainActor
class TextCleanupManager {

    private let instructions = "You are a speech dictation assistant. Fix grammar, punctuation, and remove filler words. Output ONLY the final cleaned text without any intro, explanation, or rules."

    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    func cleanTranscript(_ rawText: String) async throws -> String {
        let trimmedRaw = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRaw.isEmpty else { return "" }

        guard isAvailable else {
            return basicCleanup(trimmedRaw)
        }

        let prompt = "Clean up the following dictated text and output ONLY the final text:\n\n\(trimmedRaw)"
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        let result = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitizeOutput(result, originalRaw: trimmedRaw)
    }

    /// Strips any accidental conversational intro or system prompt echo from the LLM response.
    private func sanitizeOutput(_ output: String, originalRaw: String) -> String {
        var text = output

        // If the model echoed system instructions or rules, extract the final line
        if text.contains("Rules:") || text.contains("dictation cleanup assistant") {
            if let lastLine = text.components(separatedBy: "\n").last?.trimmingCharacters(in: .whitespacesAndNewlines),
               !lastLine.isEmpty && !lastLine.contains("Rules:") {
                text = lastLine
            } else {
                return basicCleanup(originalRaw)
            }
        }

        // Strip common conversational prefixes
        let prefixesToStrip = [
            "Sure, here is the cleaned text:",
            "Here is the cleaned text:",
            "Cleaned text:",
            "Output:",
            "Sure,"
        ]

        for prefix in prefixesToStrip {
            if text.hasPrefix(prefix) {
                text = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Remove surrounding quotes if the model wrapped the result in quotes
        if text.hasPrefix("\"") && text.hasSuffix("\"") && text.count > 2 {
            text = String(text.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        }

        return text.isEmpty ? basicCleanup(originalRaw) : text
    }

    /// Triggers model load on app launch to reduce first-inference latency.
    func prewarm() {
        guard isAvailable else { return }
        Task {
            let session = LanguageModelSession()
            _ = try? await session.respond(to: "Hello")
        }
    }

    /// Lightweight regex fallback when Apple Intelligence is unavailable.
    private func basicCleanup(_ text: String) -> String {
        var cleaned = text
        let fillers = [
            "\\bum\\b,?\\s*", "\\buh\\b,?\\s*", "\\bah\\b,?\\s*",
            "\\byou know\\b,?\\s*", "\\bbasically\\b,?\\s*",
            "\\bsort of\\b,?\\s*", "\\bkind of\\b,?\\s*"
        ]
        for pattern in fillers {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    range: NSRange(cleaned.startIndex..., in: cleaned),
                    withTemplate: ""
                )
            }
        }
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
}
