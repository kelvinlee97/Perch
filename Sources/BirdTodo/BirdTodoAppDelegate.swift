import AppKit

@MainActor
final class BirdTodoAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let birdSize = CGSize(width: 88, height: 88)
    private var birdWindow: NSPanel?
    private var workspaceWindow: NSPanel?
    private var settingsWindow: NSPanel?
    private var statusItem: NSStatusItem?
    private var taskRepository: TaskRepository?
    private let shortcutStore = ShortcutStore()
    private var shortcutMenuItems: [ShortcutAction: [NSMenuItem]] = [:]

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

    func applicationDidBecomeActive(_ notification: Notification) {
        showBird()
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        showBird()
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === workspaceWindow {
            workspaceWindow = nil
        } else if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
        }
        showBird()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func showQuickCapture() {
        showWorkspace()
    }

    @objc private func closeWorkspace() {
        workspaceWindow?.close()
    }

    @objc private func showSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let size = CGSize(width: 440, height: 430)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "设置"
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = ShortcutSettingsView(
            frame: NSRect(origin: .zero, size: size),
            shortcutStore: shortcutStore,
            onShortcutsChanged: { [weak self] in self?.updateShortcutMenuItems() }
        )
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = panel
    }

    @objc private func showInbox() {
        showWorkspace(section: .inbox)
    }

    @objc private func showToday() {
        showWorkspace(section: .today)
    }

    @objc private func showCompleted() {
        showWorkspace(section: .completed)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "bird.fill",
            accessibilityDescription: "Bird Todo"
        )

        let menu = NSMenu()
        addShortcutMenuItem(.newTask, to: menu)
        menu.addItem(withTitle: "显示待办", action: #selector(showQuickCapture), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "小鸟回到右下角", action: #selector(showBirdFromMenu), keyEquivalent: "")
        menu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: "")
        menu.addItem(.separator())
        addShortcutMenuItem(.quit, to: menu)
        item.menu = menu
        statusItem = item
        configureMainMenu()
        updateShortcutMenuItems()
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Bird Todo")
        appMenu.addItem(withTitle: "关于 Bird Todo", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        addShortcutMenuItem(.settings, to: appMenu)
        appMenu.addItem(.separator())
        addShortcutMenuItem(.quit, to: appMenu)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "文件")
        addShortcutMenuItem(.newTask, to: fileMenu)
        addShortcutMenuItem(.closeWindow, to: fileMenu)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "查看")
        addShortcutMenuItem(.inbox, to: viewMenu)
        addShortcutMenuItem(.today, to: viewMenu)
        addShortcutMenuItem(.completed, to: viewMenu)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func addShortcutMenuItem(_ action: ShortcutAction, to menu: NSMenu) {
        let item = NSMenuItem(title: action.title, action: selector(for: action), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        shortcutMenuItems[action, default: []].append(item)
    }

    private func updateShortcutMenuItems() {
        ShortcutAction.allCases.forEach { action in
            let shortcut = shortcutStore.shortcut(for: action)
            shortcutMenuItems[action]?.forEach { item in
                item.keyEquivalent = shortcut.key
                item.keyEquivalentModifierMask = shortcut.modifierFlags
            }
        }
    }

    private func selector(for action: ShortcutAction) -> Selector {
        switch action {
        case .newTask: #selector(showQuickCapture)
        case .closeWindow: #selector(closeWorkspace)
        case .quit: #selector(quit)
        case .settings: #selector(showSettings)
        case .inbox: #selector(showInbox)
        case .today: #selector(showToday)
        case .completed: #selector(showCompleted)
        }
    }

    private func showBird() {
        guard let screen = NSScreen.main else { return }

        let frame = BirdWindowLayout.frame(in: screen.visibleFrame, size: birdSize, corner: .bottomRight)
        if let birdWindow {
            birdWindow.setFrame(frame, display: true)
            birdWindow.orderFrontRegardless()
            return
        }
        let panel = BirdPanel(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let button = BirdWidgetButton(frame: NSRect(origin: .zero, size: birdSize))
        button.toolTip = "打开 Bird Todo"
        button.target = self
        button.action = #selector(showQuickCapture)
        panel.contentView = button
        panel.orderFrontRegardless()
        birdWindow = panel
    }

    @objc private func showBirdFromMenu() {
        showBird()
    }

    private func showWorkspace(section: TodoWorkspaceView.Section? = nil) {
        if let workspaceWindow {
            workspaceWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            let workspaceView = workspaceWindow.contentView as? TodoWorkspaceView
            if let section {
                workspaceView?.select(section: section)
            } else {
                workspaceView?.focusInput()
            }
            return
        }

        let size = CGSize(width: 720, height: 560)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Bird Todo"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.minSize = CGSize(width: 620, height: 460)
        let workspaceView = TodoWorkspaceView(
            frame: NSRect(origin: .zero, size: size),
            tasks: { [weak self] in self?.taskRepository?.tasks ?? [] },
            onCreate: { [weak self] title, reminder in
                self?.createTask(title: title, reminder: reminder)
            },
            onComplete: { [weak self] id in
                self?.completeTask(id: id)
            },
            onUpdateReminder: { [weak self] id, reminder in
                self?.updateReminder(id: id, reminder: reminder)
            },
            onDelete: { [weak self] id in
                self?.deleteTask(id: id)
            },
            onDeleteMany: { [weak self] ids in
                self?.deleteTasks(ids: ids)
            },
            onOpenSettings: { [weak self] in
                self?.showSettings()
            }
        )
        panel.contentView = workspaceView
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        birdWindow?.orderFrontRegardless()
        if let section {
            workspaceView.select(section: section)
        } else {
            workspaceView.focusInput()
        }
        workspaceWindow = panel
    }

    private func createTask(title: String, reminder: QuickReminder) -> String? {
        do {
            guard let taskRepository else {
                return "待办尚未准备好，请稍后再试。"
            }
            _ = try taskRepository.create(title: title, reminderAt: reminder.reminderDate())
            return nil
        } catch TaskStoreError.emptyTitle {
            return TaskStoreError.emptyTitle.localizedDescription
        } catch {
            return "无法保存待办，请稍后再试。"
        }
    }

    private func completeTask(id: UUID) -> String? {
        do {
            _ = try taskRepository?.complete(id: id)
            return nil
        } catch {
            return "无法更新待办，请稍后再试。"
        }
    }

    private func updateReminder(id: UUID, reminder: QuickReminder) -> String? {
        do {
            _ = try taskRepository?.updateReminder(id: id, reminderAt: reminder.reminderDate())
            return nil
        } catch {
            return "无法更新待办，请稍后再试。"
        }
    }

    private func deleteTask(id: UUID) -> String? {
        do {
            _ = try taskRepository?.delete(id: id)
            return nil
        } catch {
            return "无法删除待办，请稍后再试。"
        }
    }

    private func deleteTasks(ids: Set<UUID>) -> String? {
        do {
            _ = try taskRepository?.delete(ids: ids)
            return nil
        } catch {
            return "无法删除待办，请稍后再试。"
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
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class TodoWorkspaceView: NSView {
    fileprivate enum Section: CaseIterable {
        case inbox
        case today
        case completed

        var title: String {
            switch self {
            case .inbox: "收集箱"
            case .today: "今天"
            case .completed: "已完成"
            }
        }

        var icon: String {
            switch self {
            case .inbox: "tray"
            case .today: "sun.max"
            case .completed: "checkmark.circle"
            }
        }

        var status: TaskStatus {
            switch self {
            case .inbox: .inbox
            case .today: .today
            case .completed: .completed
            }
        }
    }

    private let taskProvider: () -> [Task]
    private let onCreate: (String, QuickReminder) -> String?
    private let onComplete: (UUID) -> String?
    private let onUpdateReminder: (UUID, QuickReminder) -> String?
    private let onDelete: (UUID) -> String?
    private let onDeleteMany: (Set<UUID>) -> String?
    private let onOpenSettings: () -> Void
    private let inputField = NSTextField()
    private let messageLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let taskStack = TaskListStackView()
    private let completedVisibilityButton = NSButton()
    private let selectionButton = NSButton()
    private let selectAllButton = NSButton()
    private let batchDeleteButton = NSButton()
    private var sectionButtons: [Section: NSButton] = [:]
    private var selectedSection: Section = .today
    private var areCompletedHidden = false
    private var isSelecting = false
    private var selectedTaskIDs = Set<UUID>()

    init(
        frame frameRect: NSRect,
        tasks: @escaping () -> [Task],
        onCreate: @escaping (String, QuickReminder) -> String?,
        onComplete: @escaping (UUID) -> String?,
        onUpdateReminder: @escaping (UUID, QuickReminder) -> String?,
        onDelete: @escaping (UUID) -> String?,
        onDeleteMany: @escaping (Set<UUID>) -> String?,
        onOpenSettings: @escaping () -> Void
    ) {
        taskProvider = tasks
        self.onCreate = onCreate
        self.onComplete = onComplete
        self.onUpdateReminder = onUpdateReminder
        self.onDelete = onDelete
        self.onDeleteMany = onDeleteMany
        self.onOpenSettings = onOpenSettings
        super.init(frame: frameRect)
        buildInterface()
        refresh()
    }

    required init?(coder: NSCoder) { nil }

    func focusInput() {
        messageLabel.stringValue = ""
        window?.makeFirstResponder(inputField)
    }

    func select(section: Section) {
        selectedSection = section
        refresh()
    }

    private func buildInterface() {
        let material = NSVisualEffectView()
        material.material = .underWindowBackground
        material.blendingMode = .behindWindow
        material.state = .active
        material.translatesAutoresizingMaskIntoConstraints = false
        addSubview(material)

        let sidebar = NSVisualEffectView()
        sidebar.material = .sidebar
        sidebar.blendingMode = .withinWindow
        sidebar.state = .active
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        material.addSubview(sidebar)

        let content = NSVisualEffectView()
        content.material = .contentBackground
        content.blendingMode = .withinWindow
        content.state = .active
        content.translatesAutoresizingMaskIntoConstraints = false
        material.addSubview(content)

        let brandImage = NSImageView()
        brandImage.image = NSImage(systemSymbolName: "bird.fill", accessibilityDescription: nil)
        brandImage.contentTintColor = NSColor(calibratedRed: 0.16, green: 0.34, blue: 0.26, alpha: 1)
        brandImage.translatesAutoresizingMaskIntoConstraints = false
        let brandTitle = NSTextField(labelWithString: "Bird Todo")
        brandTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        let brand = NSStackView(views: [brandImage, brandTitle])
        brand.orientation = .horizontal
        brand.alignment = .centerY
        brand.spacing = 8
        brand.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(brand)

        let navigation = NSStackView()
        navigation.orientation = .vertical
        navigation.alignment = .leading
        navigation.spacing = 4
        navigation.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(navigation)
        Section.allCases.forEach { section in
            let button = NSButton(title: section.title, image: NSImage(systemSymbolName: section.icon, accessibilityDescription: nil) ?? NSImage(), target: self, action: #selector(selectSection(_:)))
            button.identifier = NSUserInterfaceItemIdentifier(section.title)
            button.imagePosition = .imageLeading
            button.contentTintColor = .secondaryLabelColor
            button.font = .systemFont(ofSize: 13, weight: .medium)
            button.bezelStyle = .inline
            button.isBordered = false
            button.alignment = .left
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 156).isActive = true
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
            navigation.addArrangedSubview(button)
            sectionButtons[section] = button
        }

        completedVisibilityButton.title = "隐藏已完成"
        completedVisibilityButton.target = self
        completedVisibilityButton.action = #selector(toggleCompletedVisibility)
        completedVisibilityButton.bezelStyle = .inline
        completedVisibilityButton.font = .systemFont(ofSize: 12)
        completedVisibilityButton.contentTintColor = .secondaryLabelColor
        completedVisibilityButton.alignment = .left
        completedVisibilityButton.translatesAutoresizingMaskIntoConstraints = false
        completedVisibilityButton.widthAnchor.constraint(equalToConstant: 156).isActive = true
        navigation.addArrangedSubview(completedVisibilityButton)

        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(titleLabel)

        selectionButton.title = "选择"
        selectionButton.target = self
        selectionButton.action = #selector(toggleSelectionMode)
        selectionButton.bezelStyle = .texturedRounded
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(selectionButton)

        selectAllButton.title = "全选"
        selectAllButton.target = self
        selectAllButton.action = #selector(toggleSelectAll)
        selectAllButton.bezelStyle = .texturedRounded
        selectAllButton.isHidden = true
        selectAllButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(selectAllButton)

        batchDeleteButton.title = "删除所选"
        batchDeleteButton.target = self
        batchDeleteButton.action = #selector(deleteSelectedTasks)
        batchDeleteButton.bezelStyle = .texturedRounded
        batchDeleteButton.contentTintColor = .systemRed
        batchDeleteButton.isHidden = true
        batchDeleteButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(batchDeleteButton)

        inputField.placeholderString = "记下待办…"
        inputField.font = .systemFont(ofSize: 15)
        inputField.target = self
        inputField.action = #selector(createInboxTask)
        inputField.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(inputField)

        let addButton = NSButton(title: "添加", target: self, action: #selector(createInboxTask))
        addButton.bezelStyle = .rounded
        addButton.font = .systemFont(ofSize: 13, weight: .medium)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(addButton)

        let quickActions = NSStackView()
        quickActions.orientation = .horizontal
        quickActions.spacing = 8
        quickActions.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(quickActions)
        addQuickAction(title: "收集箱", reminder: .none, to: quickActions)
        addQuickAction(title: "10 分钟", reminder: .tenMinutes, to: quickActions)
        addQuickAction(title: "今晚", reminder: .tonight, to: quickActions)
        addQuickAction(title: "明天", reminder: .tomorrow, to: quickActions)

        messageLabel.font = .systemFont(ofSize: 12)
        messageLabel.textColor = .systemRed
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(messageLabel)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(scrollView)
        taskStack.orientation = .vertical
        taskStack.alignment = .width
        taskStack.spacing = 0
        taskStack.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 12, right: 8)
        taskStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = taskStack

        NSLayoutConstraint.activate([
            material.leadingAnchor.constraint(equalTo: leadingAnchor),
            material.trailingAnchor.constraint(equalTo: trailingAnchor),
            material.topAnchor.constraint(equalTo: topAnchor),
            material.bottomAnchor.constraint(equalTo: bottomAnchor),
            sidebar.leadingAnchor.constraint(equalTo: material.leadingAnchor),
            sidebar.topAnchor.constraint(equalTo: material.topAnchor),
            sidebar.bottomAnchor.constraint(equalTo: material.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 188),
            content.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            content.trailingAnchor.constraint(equalTo: material.trailingAnchor),
            content.topAnchor.constraint(equalTo: material.topAnchor),
            content.bottomAnchor.constraint(equalTo: material.bottomAnchor),
            brand.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 20),
            brand.topAnchor.constraint(equalTo: sidebar.topAnchor, constant: 26),
            brandImage.widthAnchor.constraint(equalToConstant: 18),
            brandImage.heightAnchor.constraint(equalToConstant: 18),
        navigation.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 16),
        navigation.topAnchor.constraint(equalTo: brand.bottomAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
            titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: batchDeleteButton.leadingAnchor, constant: -12),
            selectionButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -28),
            selectionButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            selectAllButton.trailingAnchor.constraint(equalTo: selectionButton.leadingAnchor, constant: -8),
            selectAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            batchDeleteButton.trailingAnchor.constraint(equalTo: selectAllButton.leadingAnchor, constant: -8),
            batchDeleteButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            inputField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
            inputField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            inputField.heightAnchor.constraint(equalToConstant: 32),
            addButton.leadingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -28),
            addButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 52),
            quickActions.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
            quickActions.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
            messageLabel.topAnchor.constraint(equalTo: quickActions.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
            scrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            taskStack.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            taskStack.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor)
        ])

        let settingsButton = NSButton(
            title: "设置…",
            image: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) ?? NSImage(),
            target: self,
            action: #selector(openSettings)
        )
        settingsButton.imagePosition = .imageLeading
        settingsButton.bezelStyle = .inline
        settingsButton.isBordered = false
        settingsButton.alignment = .left
        settingsButton.font = .systemFont(ofSize: 13, weight: .medium)
        settingsButton.contentTintColor = .secondaryLabelColor
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        sidebar.addSubview(settingsButton)
        NSLayoutConstraint.activate([
            settingsButton.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 16),
            settingsButton.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 156),
            settingsButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    private func addQuickAction(title: String, reminder: QuickReminder, to stack: NSStackView) {
        let button = NSButton(title: title, target: self, action: #selector(createQuickTask(_:)))
        button.tag = reminderTag(for: reminder)
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 12, weight: .medium)
        stack.addArrangedSubview(button)
    }

    @objc private func selectSection(_ sender: NSButton) {
        guard let section = Section.allCases.first(where: { $0.title == sender.identifier?.rawValue }) else { return }
        selectedSection = section
        refresh()
    }

    @objc private func toggleCompletedVisibility() {
        areCompletedHidden.toggle()
        sectionButtons[.completed]?.isHidden = areCompletedHidden
        completedVisibilityButton.title = areCompletedHidden ? "显示已完成" : "隐藏已完成"
        if areCompletedHidden && selectedSection == .completed {
            selectedSection = .today
        }
        refresh()
    }

    @objc private func toggleSelectionMode() {
        isSelecting.toggle()
        if !isSelecting {
            selectedTaskIDs.removeAll()
        }
        selectionButton.title = isSelecting ? "完成选择" : "选择"
        batchDeleteButton.isHidden = !isSelecting
        selectAllButton.isHidden = !isSelecting
        updateBatchDeleteButton()
        refresh()
    }

    @objc private func toggleSelectAll() {
        let visibleIDs = Set(taskProvider()
            .filter { $0.status == selectedSection.status }
            .map(\.id))
        if !visibleIDs.isEmpty && visibleIDs.isSubset(of: selectedTaskIDs) {
            selectedTaskIDs.subtract(visibleIDs)
        } else {
            selectedTaskIDs.formUnion(visibleIDs)
        }
        refresh()
    }

    @objc private func deleteSelectedTasks() {
        guard !selectedTaskIDs.isEmpty else {
            messageLabel.textColor = .systemRed
            messageLabel.stringValue = "请先选择待办。"
            return
        }

        let alert = NSAlert()
        alert.messageText = "删除 \(selectedTaskIDs.count) 项待办？"
        alert.informativeText = "此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        perform { onDeleteMany(selectedTaskIDs) }
        isSelecting = false
        selectedTaskIDs.removeAll()
        selectionButton.title = "选择"
        batchDeleteButton.isHidden = true
        selectAllButton.isHidden = true
    }

    @objc private func createInboxTask() {
        createTask(with: .none)
    }

    @objc private func createQuickTask(_ sender: NSButton) {
        createTask(with: reminder(for: sender.tag))
    }

    private func createTask(with reminder: QuickReminder) {
        if let errorMessage = onCreate(inputField.stringValue, reminder) {
            messageLabel.textColor = .systemRed
            messageLabel.stringValue = errorMessage
            return
        }
        inputField.stringValue = ""
        messageLabel.textColor = .systemGreen
        messageLabel.stringValue = reminder == .none ? "已加入收集箱。" : "提醒已设置。"
        selectedSection = reminder == .none ? .inbox : .today
        refresh()
    }

    private func refresh() {
        titleLabel.stringValue = selectedSection.title
        let tasks = taskProvider()
        selectedTaskIDs.formIntersection(Set(tasks.map(\.id)))
        updateBatchDeleteButton()
        Section.allCases.forEach { section in
            let count = tasks.filter { $0.status == section.status }.count
            sectionButtons[section]?.title = "\(section.title)  \(count)"
            sectionButtons[section]?.contentTintColor = section == selectedSection ? .controlAccentColor : .secondaryLabelColor
            sectionButtons[section]?.state = section == selectedSection ? .on : .off
        }
        taskStack.arrangedSubviews.forEach {
            taskStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let visibleTasks = tasks
            .filter { $0.status == selectedSection.status }
            .sorted { $0.createdAt > $1.createdAt }
        if visibleTasks.isEmpty {
            let empty = NSTextField(labelWithString: emptyMessage(for: selectedSection))
            empty.alignment = .center
            empty.textColor = .secondaryLabelColor
            empty.font = .systemFont(ofSize: 14)
            empty.heightAnchor.constraint(equalToConstant: 120).isActive = true
            taskStack.addArrangedSubview(empty)
            return
        }

        visibleTasks.forEach { task in
            let row = TaskRowView(
                task: task,
                isSelecting: isSelecting,
                isSelected: selectedTaskIDs.contains(task.id),
                onSelect: { [weak self] id in self?.toggleSelection(for: id) },
                onComplete: { [weak self] id in self?.perform { self?.onComplete(id) } },
                onUpdateReminder: { [weak self] id, reminder in self?.perform { self?.onUpdateReminder(id, reminder) } },
                onDelete: { [weak self] id in self?.perform { self?.onDelete(id) } }
            )
            taskStack.addArrangedSubview(row)
        }
    }

    private func perform(_ action: () -> String?) {
        messageLabel.stringValue = action() ?? ""
        refresh()
    }

    private func toggleSelection(for id: UUID) {
        if selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        } else {
            selectedTaskIDs.insert(id)
        }
        refresh()
    }

    private func updateBatchDeleteButton() {
        batchDeleteButton.title = selectedTaskIDs.isEmpty
            ? "删除所选"
            : "删除所选 \(selectedTaskIDs.count)"
        batchDeleteButton.isEnabled = !selectedTaskIDs.isEmpty
        let visibleIDs = Set(taskProvider()
            .filter { $0.status == selectedSection.status }
            .map(\.id))
        selectAllButton.title = !visibleIDs.isEmpty && visibleIDs.isSubset(of: selectedTaskIDs)
            ? "取消全选"
            : "全选"
        selectAllButton.isEnabled = !visibleIDs.isEmpty
    }

    private func emptyMessage(for section: Section) -> String {
        switch section {
        case .inbox: "收集箱是空的。记下一件想做的事。"
        case .today: "今天还没有安排。"
        case .completed: "完成的任务会出现在这里。"
        }
    }

    private func reminderTag(for reminder: QuickReminder) -> Int {
        switch reminder {
        case .none: 0
        case .tenMinutes: 1
        case .tonight: 2
        case .tomorrow: 3
        }
    }

    private func reminder(for tag: Int) -> QuickReminder {
        switch tag {
        case 1: .tenMinutes
        case 2: .tonight
        case 3: .tomorrow
        default: .none
        }
    }
}

private final class TaskListStackView: NSStackView {
    override var isFlipped: Bool { true }
}

private final class TaskRowView: NSView {
    private let task: Task
    private let isSelecting: Bool
    private let isSelected: Bool
    private let onSelect: (UUID) -> Void
    private let onComplete: (UUID) -> Void
    private let onUpdateReminder: (UUID, QuickReminder) -> Void
    private let onDelete: (UUID) -> Void

    init(
        task: Task,
        isSelecting: Bool,
        isSelected: Bool,
        onSelect: @escaping (UUID) -> Void,
        onComplete: @escaping (UUID) -> Void,
        onUpdateReminder: @escaping (UUID, QuickReminder) -> Void,
        onDelete: @escaping (UUID) -> Void
    ) {
        self.task = task
        self.isSelecting = isSelecting
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onComplete = onComplete
        self.onUpdateReminder = onUpdateReminder
        self.onDelete = onDelete
        super.init(frame: .zero)
        buildInterface()
    }

    required init?(coder: NSCoder) { nil }

    private func buildInterface() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 48).isActive = true

        let completeButton = NSButton(
            image: NSImage(
                systemSymbolName: isSelecting ? (isSelected ? "checkmark.circle.fill" : "circle") : (task.status == .completed ? "checkmark.circle.fill" : "circle"),
                accessibilityDescription: isSelecting
                    ? "选择待办"
                    : (task.status == .completed ? "已完成" : "完成待办")
            ) ?? NSImage(),
            target: self,
            action: #selector(performPrimaryAction)
        )
        completeButton.bezelStyle = .inline
        completeButton.contentTintColor = task.status == .completed ? .controlAccentColor : .secondaryLabelColor
        completeButton.isEnabled = task.status != .completed
        completeButton.isHidden = isSelecting
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(completeButton)

        let selectButton = NSButton(checkboxWithTitle: "", target: self, action: #selector(selectTask))
        selectButton.state = isSelected ? .on : .off
        selectButton.isHidden = !isSelecting
        selectButton.toolTip = isSelected ? "取消选择" : "选择待办"
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectButton)

        let title = NSTextField(labelWithString: task.title)
        title.font = .systemFont(ofSize: 14)
        title.lineBreakMode = .byTruncatingTail
        if task.status == .completed {
            title.textColor = .secondaryLabelColor
        }
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)

        let reminder = NSTextField(labelWithString: reminderText())
        reminder.font = .systemFont(ofSize: 12)
        reminder.textColor = .secondaryLabelColor
        reminder.alignment = .right
        reminder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reminder)

        let actions = NSButton(image: NSImage(systemSymbolName: "ellipsis", accessibilityDescription: "待办操作") ?? NSImage(), target: self, action: #selector(showActions(_:)))
        actions.bezelStyle = .inline
        actions.isHidden = isSelecting
        actions.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actions)

        NSLayoutConstraint.activate([
            completeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            completeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 30),
            selectButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            selectButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            selectButton.widthAnchor.constraint(equalToConstant: 30),
            title.leadingAnchor.constraint(equalTo: completeButton.trailingAnchor, constant: 4),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            reminder.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 12),
            reminder.centerYAnchor.constraint(equalTo: centerYAnchor),
            actions.leadingAnchor.constraint(equalTo: reminder.trailingAnchor, constant: 6),
            actions.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            actions.centerYAnchor.constraint(equalTo: centerYAnchor),
            actions.widthAnchor.constraint(equalToConstant: 28),
            reminder.widthAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func reminderText() -> String {
        guard let reminderAt = task.reminderAt else { return "" }
        return DateFormatter.localizedString(from: reminderAt, dateStyle: .none, timeStyle: .short)
    }

    @objc private func performPrimaryAction() {
        if isSelecting {
            onSelect(task.id)
        } else {
            onComplete(task.id)
        }
    }

    @objc private func selectTask() {
        onSelect(task.id)
    }

    @objc private func showActions(_ sender: NSButton) {
        let menu = NSMenu()
        addMenuItem("移到收集箱", action: #selector(clearReminder), to: menu)
        addMenuItem("10 分钟后", action: #selector(remindInTenMinutes), to: menu)
        addMenuItem("今晚", action: #selector(remindTonight), to: menu)
        addMenuItem("明天", action: #selector(remindTomorrow), to: menu)
        menu.addItem(.separator())
        addMenuItem("删除", action: #selector(deleteTask), to: menu)
        menu.popUp(positioning: nil, at: NSPoint(x: sender.bounds.midX, y: sender.bounds.minY), in: sender)
    }

    private func addMenuItem(_ title: String, action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private func clearReminder() { onUpdateReminder(task.id, .none) }
    @objc private func remindInTenMinutes() { onUpdateReminder(task.id, .tenMinutes) }
    @objc private func remindTonight() { onUpdateReminder(task.id, .tonight) }
    @objc private func remindTomorrow() { onUpdateReminder(task.id, .tomorrow) }
    @objc private func deleteTask() {
        let alert = NSAlert()
        alert.messageText = "删除这项待办？"
        alert.informativeText = "此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        onDelete(task.id)
    }
}
