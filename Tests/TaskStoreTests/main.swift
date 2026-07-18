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

func testCompletesAnInboxTask() throws {
    let store = TaskStore()
    let task = try store.create(title: "Review proposal")

    let completedTask = store.complete(id: task.id)

    expect(completedTask?.status == .completed, "completing a task moves it to Completed")
    expect(store.tasks.first?.status == .completed, "the stored task is completed")
}

func testChangesACompletedTaskBackToInboxWhenItsReminderIsCleared() throws {
    let store = TaskStore()
    let task = try store.create(title: "Send notes", reminderAt: Date())
    _ = store.complete(id: task.id)

    let updatedTask = store.updateReminder(id: task.id, reminderAt: nil)

    expect(updatedTask?.status == .inbox, "clearing a reminder returns a task to Inbox")
    expect(updatedTask?.reminderAt == nil, "clearing a reminder removes its date")
}

func testChangesATaskToTodayWhenItReceivesAReminder() throws {
    let store = TaskStore()
    let task = try store.create(title: "Book flights")
    let reminder = Date(timeIntervalSinceReferenceDate: 12_345)

    let updatedTask = store.updateReminder(id: task.id, reminderAt: reminder)

    expect(updatedTask?.status == .today, "adding a reminder moves a task to Today")
    expect(updatedTask?.reminderAt == reminder, "the reminder is retained")
}

func testDeletesATaskAndPersistsTheRemoval() throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let repository = try TaskRepository(fileURL: fileURL)
    let task = try repository.create(title: "Delete me")

    let wasDeleted = try repository.delete(id: task.id)
    expect(wasDeleted, "an existing task is deleted")
    let reopenedRepository = try TaskRepository(fileURL: fileURL)
    expect(reopenedRepository.tasks.isEmpty, "a deleted task does not return after reopening")
}

func testDeletesSelectedTasksAndPersistsTheRemoval() throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let repository = try TaskRepository(fileURL: fileURL)
    let first = try repository.create(title: "First")
    let second = try repository.create(title: "Second")
    let third = try repository.create(title: "Third")

    let deletedCount = try repository.delete(ids: Set([first.id, third.id]))
    expect(deletedCount == 2, "all selected tasks are deleted")

    let reopenedRepository = try TaskRepository(fileURL: fileURL)
    expect(reopenedRepository.tasks == [second], "only unselected tasks remain after reopening")
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
    try testCompletesAnInboxTask()
    try testChangesACompletedTaskBackToInboxWhenItsReminderIsCleared()
    try testChangesATaskToTodayWhenItReceivesAReminder()
    try testDeletesATaskAndPersistsTheRemoval()
    try testDeletesSelectedTasksAndPersistsTheRemoval()
    testSelectsTheOldestDueTask()
    testQuickReminderTimesArePredictable()
    print("TaskStore tests passed.")
} catch {
    fatalError("Test failed: \(error)")
}
