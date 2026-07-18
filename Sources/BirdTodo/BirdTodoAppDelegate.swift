import AppKit

@MainActor
final class BirdTodoAppDelegate: NSObject, NSApplicationDelegate {
    private let birdSize = CGSize(width: 88, height: 88)
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
        showCapture()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        showCapture()
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

    @objc private func showQuickCapture() {
        showCapture()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "bird.fill",
            accessibilityDescription: "Bird Todo"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "新建待办", action: #selector(showQuickCapture), keyEquivalent: "n")
        menu.addItem(.separator())
        menu.addItem(withTitle: "显示小鸟", action: #selector(toggleBird), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 Bird Todo", action: #selector(quit), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    private func showBird() {
        guard let screen = NSScreen.main else { return }

        let frame = BirdWindowLayout.frame(in: screen.visibleFrame, size: birdSize, corner: .bottomRight)
        let panel = BirdPanel(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let button = NSButton(frame: NSRect(origin: .zero, size: birdSize))
        button.image = NSImage(
            systemSymbolName: "bird.fill",
            accessibilityDescription: "新建待办"
        )
        button.contentTintColor = NSColor(
            calibratedRed: 0.16,
            green: 0.34,
            blue: 0.26,
            alpha: 1
        )
        button.imageScaling = .scaleProportionallyUpOrDown
        button.isBordered = false
        button.toolTip = "点击新建待办"
        button.target = self
        button.action = #selector(showQuickCapture)
        panel.contentView = button
        panel.orderFrontRegardless()
        birdWindow = panel
    }

    private func showCapture() {
        if let captureWindow, captureWindow.isVisible {
            captureWindow.makeKeyAndOrderFront(nil)
            return
        }

        guard birdWindow != nil else { return }

        let captureSize = CGSize(width: 320, height: 170)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: captureSize),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Bird Todo"
        panel.isReleasedWhenClosed = false
        let captureView = CaptureView(frame: NSRect(origin: .zero, size: captureSize)) { [weak self] title, reminder in
            self?.createTask(title: title, reminder: reminder)
        }
        panel.contentView = captureView
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeFirstResponder(captureView.inputField)
        captureWindow = panel
    }

    private func createTask(title: String, reminder: QuickReminder) -> String? {
        do {
            guard let taskRepository else {
                return "待办尚未准备好，请稍后再试。"
            }
            _ = try taskRepository.create(title: title, reminderAt: reminder.reminderDate())
            captureWindow?.orderOut(nil)
            captureWindow = nil
            return nil
        } catch TaskStoreError.emptyTitle {
            return TaskStoreError.emptyTitle.localizedDescription
        } catch {
            return "无法保存待办，请稍后再试。"
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

private final class BirdPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

private final class CaptureView: NSView {
    private let field = NSTextField()
    private let validationLabel = NSTextField(labelWithString: "")
    private let onSubmit: (String, QuickReminder) -> String?

    var inputField: NSTextField {
        field
    }

    init(frame frameRect: NSRect, onSubmit: @escaping (String, QuickReminder) -> String?) {
        self.onSubmit = onSubmit
        super.init(frame: frameRect)

        let titleLabel = NSTextField(labelWithString: "记下你要做的事")
        titleLabel.frame = NSRect(x: 16, y: 130, width: 288, height: 20)
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        addSubview(titleLabel)

        field.frame = NSRect(x: 16, y: 88, width: 288, height: 26)
        field.placeholderString = "记下待办…"
        field.font = .systemFont(ofSize: 14)
        field.target = self
        field.action = #selector(submitInbox)
        addSubview(field)

        validationLabel.frame = NSRect(x: 16, y: 68, width: 288, height: 16)
        validationLabel.textColor = .systemRed
        validationLabel.font = .systemFont(ofSize: 11)
        addSubview(validationLabel)

        addButton(title: "收集箱", action: #selector(submitInbox), x: 16)
        addButton(title: "10 分钟", action: #selector(submitTenMinutes), x: 88)
        addButton(title: "今晚", action: #selector(submitTonight), x: 160)
        addButton(title: "明天", action: #selector(submitTomorrow), x: 232)
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addButton(title: String, action: Selector, x: CGFloat) {
        let button = NSButton(title: title, target: self, action: action)
        button.frame = NSRect(x: x, y: 40, width: 66, height: 24)
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 11)
        addSubview(button)
    }

    @objc private func submitInbox() {
        submit(.none)
    }

    @objc private func submitTenMinutes() {
        submit(.tenMinutes)
    }

    @objc private func submitTonight() {
        submit(.tonight)
    }

    @objc private func submitTomorrow() {
        submit(.tomorrow)
    }

    private func submit(_ reminder: QuickReminder) {
        validationLabel.stringValue = onSubmit(field.stringValue, reminder) ?? ""
    }
}
