import AppKit

@MainActor
class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastFnPressTime: Date?
    private var isFnCurrentlyDown = false
    private var isRecordingActive = false

    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?

    func startMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            Task { @MainActor in
                self?.handleEvent(event)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            Task { @MainActor in
                self?.handleEvent(event)
            }
            return event
        }
    }

    func stopMonitoring() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handleEvent(_ event: NSEvent) {
        if event.type == .flagsChanged {
            handleFlagsChanged(event)
        } else if event.type == .keyDown {
            handleKeyDown(event)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let isFnCode = (event.keyCode == 63)
        let fnPressed = isFnCode || event.modifierFlags.contains(.function)

        if fnPressed && !isFnCurrentlyDown {
            isFnCurrentlyDown = true
            handleFnDown()
        } else if !fnPressed && isFnCurrentlyDown {
            isFnCurrentlyDown = false
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        // Fallback shortcut: Option + Space (keyCode 49)
        if event.keyCode == 49 && event.modifierFlags.contains(.option) {
            toggleDictation()
        }
    }

    private func handleFnDown() {
        let now = Date()

        if isRecordingActive {
            isRecordingActive = false
            lastFnPressTime = nil
            onRecordingStop?()
            return
        }

        if let lastPress = lastFnPressTime,
           now.timeIntervalSince(lastPress) <= VFConstants.doubleTapInterval {
            isRecordingActive = true
            lastFnPressTime = nil
            onRecordingStart?()
        } else {
            lastFnPressTime = now
        }
    }

    func toggleDictation() {
        if isRecordingActive {
            isRecordingActive = false
            onRecordingStop?()
        } else {
            isRecordingActive = true
            onRecordingStart?()
        }
    }


}
