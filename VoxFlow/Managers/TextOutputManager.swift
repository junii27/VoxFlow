import AppKit
@preconcurrency import ApplicationServices

@MainActor
class TextOutputManager {

    /// Copies cleaned text to clipboard, simulates Cmd+V, then restores previous clipboard.
    func outputText(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + VFConstants.pasteDelay) { [weak self] in
            self?.simulatePaste()

            // Restore original clipboard after paste completes
            DispatchQueue.main.asyncAfter(deadline: .now() + VFConstants.clipboardRestoreDelay) {
                if let previous = previousContents {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                }
            }
        }
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // 0x09 = virtual key code for 'V'
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    static func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
