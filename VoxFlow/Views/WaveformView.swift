import SwiftUI

struct WaveformView: View {
    let levels: [Float]
    var accentColor: Color = .white

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<levels.count, id: \.self) { index in
                let level = CGFloat(levels[index])
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(accentColor.opacity(0.6 + Double(level) * 0.4))
                    .frame(width: 3, height: max(4, level * 28))
                    .animation(.spring(response: 0.15, dampingFraction: 0.6), value: level)
            }
        }
        .frame(height: 32)
    }
}
