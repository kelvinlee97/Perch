import Foundation

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

do {
    try testCreatesAnInboxTaskFromAWhitespacePaddedTitle()
    testRejectsAnEmptyTaskTitle()
    print("TaskStore tests passed.")
} catch {
    fatalError("Test failed: \(error)")
}
