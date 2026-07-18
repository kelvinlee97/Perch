import AppKit

@MainActor
final class BirdTodoAppDelegate: NSObject, NSApplicationDelegate {
    private let birdSize = CGSize(width: 64, height: 64)
    private var birdWindow: NSPanel?
    private var captureWindow: NSPanel?
    private var statusItem: NSStatusItem?
    private var taskRepository: TaskRepository?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            taskRepository = try TaskRepository(fileURL: taskFileURL())
        } catch {
            NSApp.presentError(error)
            return
        }

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
        panel.contentView = BirdView(frame: NSRect(origin: .zero, size: birdSize)) { [weak self] in
            self?.showCapture()
        }
        panel.orderFrontRegardless()
        birdWindow = panel
    }

    private func showCapture() {
        guard let birdWindow else { return }

        let captureSize = CGSize(width: 280, height: 82)
        let frame = NSRect(
            x: birdWindow.frame.maxX - captureSize.width,
            y: birdWindow.frame.maxY + 10,
            width: captureSize.width,
            height: captureSize.height
        )
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.contentView = CaptureView(frame: NSRect(origin: .zero, size: captureSize)) { [weak self] title in
            self?.createTask(title: title)
        }
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        captureWindow = panel
    }

    private func createTask(title: String) {
        do {
            _ = try taskRepository?.create(title: title)
            captureWindow?.orderOut(nil)
            captureWindow = nil
        } catch {
            NSApp.presentError(error)
        }
    }

    private func taskFileURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("BirdTodo", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("tasks.json")
    }
}

private final class BirdView: NSView {
    private let onClick: () -> Void

    init(frame frameRect: NSRect, onClick: @escaping () -> Void) {
        self.onClick = onClick
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

    override func mouseDown(with event: NSEvent) {
        onClick()
    }
}

private final class CaptureView: NSView {
    private let field = NSTextField()
    private let onSubmit: (String) -> Void

    init(frame frameRect: NSRect, onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.96).cgColor

        field.frame = NSRect(x: 14, y: 39, width: 252, height: 24)
        field.placeholderString = "记下待办…"
        field.font = .systemFont(ofSize: 14)
        addSubview(field)

        let button = NSButton(title: "添加", target: self, action: #selector(submit))
        button.frame = NSRect(x: 210, y: 10, width: 56, height: 24)
        button.bezelStyle = .rounded
        addSubview(button)
    }

    required init?(coder: NSCoder) {
        nil
    }

    @objc private func submit() {
        onSubmit(field.stringValue)
    }
}
