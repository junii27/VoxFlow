import SwiftUI
import AppKit

class DictationHUDPanel: NSPanel {

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: VFConstants.hudWidth, height: VFConstants.hudHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow

        self.contentView = NSHostingView(rootView: contentView)
    }

    func showAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - VFConstants.hudWidth / 2
        let y = screenFrame.minY + VFConstants.hudBottomPadding
        setFrameOrigin(NSPoint(x: x, y: y))

        alphaValue = 0
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = VFConstants.hudFadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    func fadeOut(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = VFConstants.hudFadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
            completion?()
        })
    }

    func updateContent(_ view: some View) {
        contentView = NSHostingView(rootView: view)
    }
}
