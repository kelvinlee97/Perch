import AppKit

enum ShortcutAction: String, CaseIterable, Codable {
    case newTask
    case closeWindow
    case quit
    case settings
    case inbox
    case today
    case completed

    var title: String {
        switch self {
        case .newTask: "新建待办"
        case .closeWindow: "关闭待办窗口"
        case .quit: "退出 Perch"
        case .settings: "打开设置"
        case .inbox: "切换到收集箱"
        case .today: "切换到今天"
        case .completed: "切换到已完成"
        }
    }

    var defaultShortcut: KeyboardShortcut {
        switch self {
        case .newTask: KeyboardShortcut(key: "n", modifiers: [.command])
        case .closeWindow: KeyboardShortcut(key: "w", modifiers: [.command])
        case .quit: KeyboardShortcut(key: "q", modifiers: [.command])
        case .settings: KeyboardShortcut(key: ",", modifiers: [.command])
        case .inbox: KeyboardShortcut(key: "1", modifiers: [.command])
        case .today: KeyboardShortcut(key: "2", modifiers: [.command])
        case .completed: KeyboardShortcut(key: "3", modifiers: [.command])
        }
    }
}

struct KeyboardShortcut: Codable, Equatable {
    let key: String
    let modifiers: UInt

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key.lowercased()
        self.modifiers = modifiers.intersection(.deviceIndependentFlagsMask).rawValue
    }

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    var displayString: String {
        let flags = modifierFlags
        var result = ""
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        return result + key.uppercased()
    }
}

final class ShortcutStore {
    private let defaults: UserDefaults
    private let storageKey = "keyboardShortcuts"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func shortcut(for action: ShortcutAction) -> KeyboardShortcut {
        shortcuts[action] ?? action.defaultShortcut
    }

    func set(_ shortcut: KeyboardShortcut, for action: ShortcutAction) {
        var updated = shortcuts
        updated[action] = shortcut
        save(updated)
    }

    func reset() {
        defaults.removeObject(forKey: storageKey)
    }

    func conflictingAction(for shortcut: KeyboardShortcut, excluding action: ShortcutAction) -> ShortcutAction? {
        ShortcutAction.allCases.first {
            $0 != action && self.shortcut(for: $0) == shortcut
        }
    }

    private var shortcuts: [ShortcutAction: KeyboardShortcut] {
        guard let data = defaults.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([ShortcutAction: KeyboardShortcut].self, from: data) else {
            return [:]
        }
        return saved
    }

    private func save(_ shortcuts: [ShortcutAction: KeyboardShortcut]) {
        guard let data = try? JSONEncoder().encode(shortcuts) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

final class ShortcutSettingsView: NSView {
    private let shortcutStore: ShortcutStore
    private let onShortcutsChanged: () -> Void
    private var recorderButtons: [ShortcutAction: ShortcutRecorderButton] = [:]
    private let messageLabel = NSTextField(labelWithString: "")

    init(frame: NSRect, shortcutStore: ShortcutStore, onShortcutsChanged: @escaping () -> Void) {
        self.shortcutStore = shortcutStore
        self.onShortcutsChanged = onShortcutsChanged
        super.init(frame: frame)
        buildInterface()
    }

    required init?(coder: NSCoder) { nil }

    private func buildInterface() {
        let title = NSTextField(labelWithString: "键盘快捷键")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)

        let explanation = NSTextField(wrappingLabelWithString: "点击快捷键后按下新的组合键。快捷键只在 Perch 位于前台时生效。")
        explanation.font = .systemFont(ofSize: 13)
        explanation.textColor = .secondaryLabelColor
        explanation.translatesAutoresizingMaskIntoConstraints = false
        addSubview(explanation)

        let rows = NSStackView()
        rows.orientation = .vertical
        rows.alignment = .width
        rows.spacing = 8
        rows.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rows)
        ShortcutAction.allCases.forEach { action in
            let label = NSTextField(labelWithString: action.title)
            label.font = .systemFont(ofSize: 13)
            let recorder = ShortcutRecorderButton(shortcut: shortcutStore.shortcut(for: action)) { [weak self] shortcut in
                self?.save(shortcut, for: action)
            }
            recorderButtons[action] = recorder
            let row = NSStackView(views: [label, recorder])
            row.orientation = .horizontal
            row.alignment = .centerY
            row.distribution = .fill
            row.spacing = 16
            label.widthAnchor.constraint(equalToConstant: 150).isActive = true
            recorder.widthAnchor.constraint(equalToConstant: 120).isActive = true
            rows.addArrangedSubview(row)
        }

        messageLabel.font = .systemFont(ofSize: 12)
        messageLabel.textColor = .systemRed
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)

        let resetButton = NSButton(title: "恢复默认快捷键", target: self, action: #selector(resetShortcuts))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(resetButton)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            explanation.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            explanation.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            explanation.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            rows.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            rows.topAnchor.constraint(equalTo: explanation.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: rows.bottomAnchor, constant: 10),
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            resetButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    private func save(_ shortcut: KeyboardShortcut, for action: ShortcutAction) {
        guard !shortcut.modifierFlags.isEmpty else {
            messageLabel.textColor = .systemRed
            messageLabel.stringValue = "请至少包含一个修饰键（⌘、⌥、⌃ 或 ⇧）。"
            recorderButtons[action]?.restoreShortcut()
            return
        }
        if let conflict = shortcutStore.conflictingAction(for: shortcut, excluding: action) {
            messageLabel.textColor = .systemRed
            messageLabel.stringValue = "“\(shortcut.displayString)”已用于“\(conflict.title)”。"
            recorderButtons[action]?.restoreShortcut()
            return
        }
        shortcutStore.set(shortcut, for: action)
        recorderButtons[action]?.shortcut = shortcut
        messageLabel.textColor = .systemRed
        messageLabel.stringValue = ""
        onShortcutsChanged()
    }

    @objc private func resetShortcuts() {
        shortcutStore.reset()
        ShortcutAction.allCases.forEach { action in
            recorderButtons[action]?.shortcut = shortcutStore.shortcut(for: action)
        }
        messageLabel.stringValue = "已恢复默认快捷键。"
        messageLabel.textColor = .systemGreen
        onShortcutsChanged()
    }
}

private final class ShortcutRecorderButton: NSButton {
    var shortcut: KeyboardShortcut {
        didSet { title = shortcut.displayString }
    }
    private let onRecord: (KeyboardShortcut) -> Void
    private var eventMonitor: Any?

    init(shortcut: KeyboardShortcut, onRecord: @escaping (KeyboardShortcut) -> Void) {
        self.shortcut = shortcut
        self.onRecord = onRecord
        super.init(frame: .zero)
        title = shortcut.displayString
        target = self
        action = #selector(beginRecording)
        bezelStyle = .rounded
        font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        toolTip = "点击后按下新的快捷键"
    }

    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { true }

    override func performClick(_ sender: Any?) {
        beginRecording()
    }

    @objc private func beginRecording() {
        window?.makeFirstResponder(self)
        title = "按下快捷键…"
        stopRecording()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window?.firstResponder === self else { return event }
            self.stopRecording()
            self.keyDown(with: event)
            return nil
        }
    }

    override func keyDown(with event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers?.lowercased(),
              characters.count == 1,
              !event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else {
            NSSound.beep()
            restoreShortcut()
            return
        }
        let recorded = KeyboardShortcut(key: characters, modifiers: event.modifierFlags)
        title = recorded.displayString
        onRecord(recorded)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self else {
            return super.performKeyEquivalent(with: event)
        }
        keyDown(with: event)
        return true
    }

    override func cancelOperation(_ sender: Any?) {
        restoreShortcut()
    }

    func restoreShortcut() {
        stopRecording()
        title = shortcut.displayString
    }

    private func stopRecording() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            stopRecording()
        }
        super.viewWillMove(toWindow: newWindow)
    }
}
