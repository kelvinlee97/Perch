import Foundation
import CoreGraphics

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("Test failed: \(message)")
    }
}

func testCreatesAnInboxTaskFromAWhitespacePaddedTitle() throws {
    let store = TaskStore()

    let task = try store.create(title: "  Confirm meeting room  ")

    expect(task.title == "Confirm meeting room", "titles are trimmed")
    expect(task.status == .inbox, "tasks without a reminder enter the inbox")
    expect(task.reminderAt == nil, "inbox tasks have no reminder")
    expect(store.tasks == [task], "created task is retained")
}

func testRejectsAnEmptyTaskTitle() {
    let store = TaskStore()

    do {
        _ = try store.create(title: "   ")
        fatalError("Test failed: empty titles are rejected")
    } catch TaskStoreError.emptyTitle {
        return
    } catch {
        fatalError("Test failed: unexpected error \(error)")
    }
}

func testDescribesAnEmptyTitleForPeople() {
    expect(
        TaskStoreError.emptyTitle.errorDescription == "请输入待办内容。",
        "empty titles have a clear validation message"
    )
}

func testPersistsCreatedTasksToDisk() throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let task = try TaskStore().create(title: "Send the agenda")
    let persistence = TaskFileStore(fileURL: fileURL)

    try persistence.save([task])

    let restoredTasks = try persistence.load()
    expect(restoredTasks == [task], "saved tasks are restored")
}

func testPlacesTheBirdInsideTheBottomRightScreenCorner() {
    let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

    let frame = BirdWindowLayout.frame(
        in: screenFrame,
        size: CGSize(width: 64, height: 64),
        corner: .bottomRight
    )

    expect(frame.origin == CGPoint(x: 1352, y: 24), "bird is inset from the bottom-right edge")
}

func testRepositoryRestoresTasksAfterItIsReopened() throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let firstLaunch = try TaskRepository(fileURL: fileURL)
    let createdTask = try firstLaunch.create(title: "Prepare slides")
    let secondLaunch = try TaskRepository(fileURL: fileURL)

    expect(secondLaunch.tasks == [createdTask], "tasks survive reopening the app")
}

func testSelectsTheOldestDueTask() {
    let now = Date(timeIntervalSinceReferenceDate: 10_000)
    let olderDueTask = Task(
        id: UUID(),
        title: "Send follow-up",
        createdAt: now,
        reminderAt: now.addingTimeInterval(-120),
        status: .today
    )
    let newerDueTask = Task(
        id: UUID(),
        title: "Join stand-up",
        createdAt: now,
        reminderAt: now.addingTimeInterval(-30),
        status: .today
    )
    let futureTask = Task(
        id: UUID(),
        title: "Review proposal",
        createdAt: now,
        reminderAt: now.addingTimeInterval(60),
        status: .today
    )

    let nextTask = ReminderQueue.nextDueTask(
        from: [newerDueTask, futureTask, olderDueTask],
        now: now
    )

    expect(nextTask == olderDueTask, "the oldest due task is shown first")
}

func testQuickReminderTimesArePredictable() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 14, minute: 30))!

    expect(
        QuickReminder.tenMinutes.reminderDate(from: now, calendar: calendar)
            == now.addingTimeInterval(600),
        "ten-minute reminders use the current time"
    )
    expect(
        QuickReminder.tonight.reminderDate(from: now, calendar: calendar)
            == calendar.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 19)),
        "tonight reminders use 19:00 today"
    )
    expect(
        QuickReminder.tomorrow.reminderDate(from: now, calendar: calendar)
            == calendar.date(from: DateComponents(year: 2026, month: 7, day: 19, hour: 9)),
        "tomorrow reminders use 09:00 tomorrow"
    )
}

do {
    try testCreatesAnInboxTaskFromAWhitespacePaddedTitle()
    testRejectsAnEmptyTaskTitle()
    testDescribesAnEmptyTitleForPeople()
    try testPersistsCreatedTasksToDisk()
    testPlacesTheBirdInsideTheBottomRightScreenCorner()
    try testRepositoryRestoresTasksAfterItIsReopened()
    testSelectsTheOldestDueTask()
    testQuickReminderTimesArePredictable()
    print("TaskStore tests passed.")
} catch {
    fatalError("Test failed: \(error)")
}
