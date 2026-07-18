import AppKit

@MainActor
final class BirdTodoAppDelegate: NSObject, NSApplicationDelegate {
    private let birdSize = CGSize(width: 64, height: 64)
    private var birdWindow: NSPanel?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        showBird()
    }

    @objc private func toggleBird() {
        guard let birdWindow else {
            showBird()
            return
        }

        if birdWindow.isVisible {
            birdWindow.orderOut(nil)
        } else {
            birdWindow.orderFrontRegardless()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "bird.fill",
            accessibilityDescription: "Bird Todo"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "Show Bird", action: #selector(toggleBird), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Bird Todo", action: #selector(quit), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    private func showBird() {
        guard let screen = NSScreen.main else { return }

        let frame = BirdWindowLayout.frame(in: screen.visibleFrame, size: birdSize, corner: .bottomRight)
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.contentView = BirdView(frame: NSRect(origin: .zero, size: birdSize))
        panel.orderFrontRegardless()
        birdWindow = panel
    }
}

private final class BirdView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let imageView = NSImageView(frame: bounds.insetBy(dx: 8, dy: 8))
        imageView.image = NSImage(
            systemSymbolName: "bird.fill",
            accessibilityDescription: "Bird Todo"
        )
        imageView.contentTintColor = NSColor(calibratedRed: 0.16, green: 0.34, blue: 0.26, alpha: 1)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        nil
    }
}
