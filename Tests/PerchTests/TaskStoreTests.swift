import Foundation
import Testing
@testable import Perch

@Suite("Task repository")
struct TaskRepositoryTests {
    @Test("A failed save does not change the in-memory tasks")
    func failedSaveDoesNotChangeTasks() throws {
        let missingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let repository = try TaskRepository(
            fileURL: missingDirectory.appendingPathComponent("tasks.json")
        )

        #expect(throws: (any Error).self) {
            try repository.create(title: "Will not be saved")
        }
        #expect(repository.tasks.isEmpty)
    }
}

@Suite("Reminder queue")
struct ReminderQueueTests {
    @Test("The earliest due today task is selected")
    func selectsEarliestDueTask() {
        let now = Date(timeIntervalSince1970: 1_000)
        let later = task(title: "Later", reminderAt: now.addingTimeInterval(-10))
        let earliest = task(title: "Earliest", reminderAt: now.addingTimeInterval(-20))
        let future = task(title: "Future", reminderAt: now.addingTimeInterval(10))
        let inbox = task(title: "Inbox", reminderAt: nil, status: .inbox)
        let completed = task(title: "Completed", reminderAt: now.addingTimeInterval(-30), status: .completed)

        let result = ReminderQueue.nextDueTask(
            from: [later, future, inbox, completed, earliest],
            now: now
        )

        #expect(result == earliest)
    }

    @Test("Due tasks contain only today tasks and are ordered by reminder time")
    func returnsOrderedDueTasks() {
        let now = Date(timeIntervalSince1970: 1_000)
        let later = task(title: "Later", reminderAt: now.addingTimeInterval(-10))
        let earliest = task(title: "Earliest", reminderAt: now.addingTimeInterval(-20))
        let future = task(title: "Future", reminderAt: now.addingTimeInterval(10))
        let inbox = task(title: "Inbox", reminderAt: nil, status: .inbox)
        let completed = task(title: "Completed", reminderAt: now.addingTimeInterval(-30), status: .completed)

        let result = ReminderQueue.dueTasks(
            from: [later, future, inbox, completed, earliest],
            now: now
        )

        #expect(result == [earliest, later])
    }

    private func task(
        title: String,
        reminderAt: Date?,
        status: TaskStatus = .today
    ) -> Task {
        Task(
            id: UUID(),
            title: title,
            createdAt: Date(timeIntervalSince1970: 0),
            reminderAt: reminderAt,
            status: status
        )
    }
}
