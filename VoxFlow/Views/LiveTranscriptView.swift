import SwiftUI

struct LiveTranscriptView: View {
    let text: String
    var maxWidth: CGFloat = 240

    var body: some View {
        Text(text.isEmpty ? "Listening..." : text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(text.isEmpty ? 0.5 : 0.9))
            .lineLimit(1)
            .truncationMode(.head)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .contentTransition(.numericText())
            .animation(.easeOut(duration: 0.15), value: text)
    }
}
