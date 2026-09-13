import AppKit

enum DueReminderAction {
    case complete
    case tenMinutes
    case tonight
    case tomorrow
    case delete
}

final class DueReminderView: NSView {
    private let onAction: (DueReminderAction) -> String?
    private let messageLabel = NSTextField(labelWithString: "")

    init(
        frame frameRect: NSRect,
        task: Task,
        additionalCount: Int,
        onAction: @escaping (DueReminderAction) -> String?
    ) {
        self.onAction = onAction
        super.init(frame: frameRect)
        buildInterface(task: task, additionalCount: additionalCount)
    }

    required init?(coder: NSCoder) { nil }

    private func buildInterface(task: Task, additionalCount: Int) {
        let background = NSVisualEffectView()
        background.material = .popover
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 14
        background.layer?.masksToBounds = true
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)

        let heading = NSTextField(labelWithString: perchLocalized("现在可以处理"))
        heading.font = .systemFont(ofSize: 12, weight: .semibold)
        heading.textColor = .secondaryLabelColor
        heading.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(heading)

        let taskButton = NSButton(title: task.title, target: self, action: #selector(completeTask))
        taskButton.bezelStyle = .inline
        taskButton.isBordered = false
        taskButton.font = .systemFont(ofSize: 15, weight: .semibold)
        taskButton.alignment = .left
        taskButton.lineBreakMode = .byTruncatingTail
        taskButton.toolTip = perchLocalized("完成这项待办")
        taskButton.setAccessibilityHelp(perchLocalized("点击后完成这项待办"))
        taskButton.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(taskButton)

        let actionsButton = NSButton(title: perchLocalized("稍后…"), target: self, action: #selector(showActions(_:)))
        actionsButton.bezelStyle = .rounded
        actionsButton.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(actionsButton)

        let countLabel = NSTextField(
            labelWithString: additionalCount > 0 ? perchLocalized("另有 %d 项到期待办", additionalCount) : ""
        )
        countLabel.font = .systemFont(ofSize: 11)
        countLabel.textColor = .tertiaryLabelColor
        countLabel.isHidden = additionalCount == 0
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(countLabel)

        messageLabel.font = .systemFont(ofSize: 11)
        messageLabel.textColor = .systemRed
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
            heading.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 16),
            heading.topAnchor.constraint(equalTo: background.topAnchor, constant: 14),
            taskButton.leadingAnchor.constraint(equalTo: heading.leadingAnchor, constant: -5),
            taskButton.trailingAnchor.constraint(equalTo: actionsButton.leadingAnchor, constant: -10),
            taskButton.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 5),
            actionsButton.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -14),
            actionsButton.centerYAnchor.constraint(equalTo: taskButton.centerYAnchor),
            actionsButton.widthAnchor.constraint(equalToConstant: 72),
            countLabel.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            countLabel.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -12),
            messageLabel.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: background.trailingAnchor, constant: -14),
            messageLabel.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor)
        ])
    }

    @objc private func completeTask() {
        perform(.complete)
    }

    @objc private func showActions(_ sender: NSButton) {
        let menu = NSMenu()
        addMenuItem(perchLocalized("10 分钟后提醒"), action: #selector(remindInTenMinutes), to: menu)
        addMenuItem(perchLocalized("今晚提醒"), action: #selector(remindTonight), to: menu)
        addMenuItem(perchLocalized("明天提醒"), action: #selector(remindTomorrow), to: menu)
        menu.addItem(.separator())
        addMenuItem(perchLocalized("删除…"), action: #selector(confirmDelete), to: menu)
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: sender.bounds.minX, y: sender.bounds.minY),
            in: sender
        )
    }

    private func addMenuItem(_ title: String, action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private func remindInTenMinutes() {
        perform(.tenMinutes)
    }

    @objc private func remindTonight() {
        perform(.tonight)
    }

    @objc private func remindTomorrow() {
        perform(.tomorrow)
    }

    @objc private func confirmDelete() {
        let alert = NSAlert()
        alert.messageText = perchLocalized("删除这项待办？")
        alert.informativeText = perchLocalized("此操作无法撤销。")
        alert.alertStyle = .warning
        alert.addButton(withTitle: perchLocalized("删除"))
        alert.addButton(withTitle: perchLocalized("取消"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        perform(.delete)
    }

    private func perform(_ action: DueReminderAction) {
        messageLabel.stringValue = onAction(action) ?? ""
    }
}
