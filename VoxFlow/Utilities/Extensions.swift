import SwiftUI
import AppKit

// MARK: - NSWorkspace

extension NSWorkspace {
    var frontmostApplicationName: String? {
        frontmostApplication?.localizedName
    }
}

// MARK: - View Helpers

extension View {
    func vfCardStyle() -> some View {
        self
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
