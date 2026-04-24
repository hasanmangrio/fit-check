import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    private var panel: NSPanel?
    private var model: NotchViewModel?
    private var mouseMonitor: Any?

    // Notch dimensions — detected at runtime via safeAreaInsets
    private let expandedWidth:  CGFloat = 300
    private let expandedHeight: CGFloat = 240

    func show() {
        guard let screen = NSScreen.main else { return }
        setupPanel(screen: screen)
        installMouseMonitor(screen: screen)
    }

    // MARK: - Panel

    private func setupPanel(screen: NSScreen) {
        let notchW = notchWidth(for: screen)
        let notchH = notchHeight(for: screen)

        let vm = NotchViewModel(
            notchSize: CGSize(width: notchW, height: notchH),
            expandedSize: CGSize(width: expandedWidth, height: expandedHeight)
        )
        model = vm

        let sf = screen.frame
        let x = sf.midX - expandedWidth / 2
        let y = sf.maxY - expandedHeight

        let p = NSPanel(
            contentRect: NSRect(x: x, y: y, width: expandedWidth, height: expandedHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.ignoresMouseEvents = true   // starts invisible to mouse; enabled on hover
        p.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        p.isMovable = false

        let hostView = NSHostingView(rootView: NotchView(model: vm))
        hostView.wantsLayer = true
        hostView.layer?.backgroundColor = CGColor.clear
        p.contentView = hostView

        p.orderFrontRegardless()
        panel = p
    }

    // MARK: - Mouse monitoring

    private func installMouseMonitor(screen: NSScreen) {
        let notchW = notchWidth(for: screen)
        let notchH = notchHeight(for: screen)
        let sf = screen.frame

        // The small rect the user must hover to trigger open
        let triggerRect = NSRect(
            x: sf.midX - notchW / 2,
            y: sf.maxY - notchH,
            width: notchW,
            height: notchH
        )

        // The full expanded rect — leaving this collapses the view
        let expandedRect = NSRect(
            x: sf.midX - expandedWidth / 2,
            y: sf.maxY - expandedHeight,
            width: expandedWidth,
            height: expandedHeight
        )

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouse = NSEvent.mouseLocation
            Task { @MainActor in
                guard let model = self.model else { return }
                if triggerRect.contains(mouse) && !model.isExpanded {
                    self.panel?.ignoresMouseEvents = false
                    model.expand()
                } else if !expandedRect.contains(mouse) && model.isExpanded {
                    model.collapse()
                    // Re-enable pass-through after collapse animation finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        self.panel?.ignoresMouseEvents = true
                    }
                }
            }
        }
    }

    // MARK: - Notch size detection

    private func notchHeight(for screen: NSScreen) -> CGFloat {
        // safeAreaInsets.top > 0 means notch is present
        screen.safeAreaInsets.top > 0 ? 37 : 24
    }

    private func notchWidth(for screen: NSScreen) -> CGFloat {
        // The notch on MacBook Pro is ~162pt; add padding for hover comfort
        screen.safeAreaInsets.top > 0 ? 185 : screen.frame.width
    }

    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
