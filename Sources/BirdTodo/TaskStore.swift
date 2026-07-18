import Foundation

enum TaskStatus: Codable, Equatable, Sendable {
    case inbox
    case today
    case completed
}

struct Task: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let createdAt: Date
    var reminderAt: Date?
    var status: TaskStatus
}

enum TaskStoreError: Error, Equatable {
    case emptyTitle
}

enum QuickReminder {
    case none
    case tenMinutes
    case tonight
    case tomorrow

    func reminderDate(from now: Date = .now, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            return nil
        case .tenMinutes:
            return now.addingTimeInterval(10 * 60)
        case .tonight:
            let tonight = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now)!
            return tonight >= now ? tonight : calendar.date(byAdding: .day, value: 1, to: tonight)
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
        }
    }
}

enum ReminderQueue {
    static func nextDueTask(from tasks: [Task], now: Date) -> Task? {
        tasks
            .filter { task in
                task.status == .today && (task.reminderAt ?? .distantFuture) <= now
            }
            .min { left, right in
                (left.reminderAt ?? .distantFuture) < (right.reminderAt ?? .distantFuture)
            }
    }
}

final class TaskStore {
    private(set) var tasks: [Task] = []

    init(tasks: [Task] = []) {
        self.tasks = tasks
    }

    @discardableResult
    func create(title: String, reminderAt: Date? = nil) throws -> Task {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw TaskStoreError.emptyTitle
        }

        let task = Task(
            id: UUID(),
            title: trimmedTitle,
            createdAt: Date(),
            reminderAt: reminderAt,
            status: reminderAt == nil ? .inbox : .today
        )
        tasks.append(task)
        return task
    }
}

final class TaskRepository {
    private let persistence: TaskFileStore
    private let store: TaskStore

    var tasks: [Task] {
        store.tasks
    }

    init(fileURL: URL) throws {
        persistence = TaskFileStore(fileURL: fileURL)
        store = TaskStore(tasks: try persistence.load())
    }

    @discardableResult
    func create(title: String, reminderAt: Date? = nil) throws -> Task {
        let task = try store.create(title: title, reminderAt: reminderAt)
        try persistence.save(store.tasks)
        return task
    }
}

struct TaskFileStore {
    let fileURL: URL

    func load() throws -> [Task] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Task].self, from: data)
    }

    func save(_ tasks: [Task]) throws {
        let data = try JSONEncoder().encode(tasks)
        try data.write(to: fileURL, options: .atomic)
    }
}
