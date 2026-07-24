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

enum TaskStoreError: Error, Equatable, LocalizedError {
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "请输入待办内容。"
        }
    }
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
        dueTasks(from: tasks, now: now).first
    }

    static func dueTasks(from tasks: [Task], now: Date) -> [Task] {
        tasks
            .filter { task in
                task.status == .today && (task.reminderAt ?? .distantFuture) <= now
            }
            .sorted { left, right in
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

    @discardableResult
    func complete(id: UUID) -> Task? {
        update(id: id) { task in
            task.status = .completed
        }
    }

    @discardableResult
    func restore(id: UUID) -> Task? {
        update(id: id) { task in
            task.status = task.reminderAt == nil ? .inbox : .today
        }
    }

    @discardableResult
    func updateReminder(id: UUID, reminderAt: Date?) -> Task? {
        update(id: id) { task in
            task.reminderAt = reminderAt
            task.status = reminderAt == nil ? .inbox : .today
        }
    }

    func delete(id: UUID) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return false
        }

        tasks.remove(at: index)
        return true
    }

    func delete(ids: Set<UUID>) -> Int {
        let originalCount = tasks.count
        tasks.removeAll { ids.contains($0.id) }
        return originalCount - tasks.count
    }

    private func update(id: UUID, mutate: (inout Task) -> Void) -> Task? {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        mutate(&tasks[index])
        return tasks[index]
    }
}

final class TaskRepository {
    private let persistence: TaskFileStore
    private var store: TaskStore

    var tasks: [Task] {
        store.tasks
    }

    init(fileURL: URL) throws {
        persistence = TaskFileStore(fileURL: fileURL)
        store = TaskStore(tasks: try persistence.load())
    }

    @discardableResult
    func create(title: String, reminderAt: Date? = nil) throws -> Task {
        try commit { store in
            try store.create(title: title, reminderAt: reminderAt)
        }
    }

    @discardableResult
    func complete(id: UUID) throws -> Task? {
        try commit { store in
            store.complete(id: id)
        }
    }

    @discardableResult
    func restore(id: UUID) throws -> Task? {
        try commit { store in
            store.restore(id: id)
        }
    }

    @discardableResult
    func updateReminder(id: UUID, reminderAt: Date?) throws -> Task? {
        try commit { store in
            store.updateReminder(id: id, reminderAt: reminderAt)
        }
    }

    func delete(id: UUID) throws -> Bool {
        try commit { store in
            store.delete(id: id)
        }
    }

    func delete(ids: Set<UUID>) throws -> Int {
        try commit { store in
            store.delete(ids: ids)
        }
    }

    private func commit<Result>(_ mutate: (TaskStore) throws -> Result) throws -> Result {
        let candidate = TaskStore(tasks: store.tasks)
        let result = try mutate(candidate)
        if candidate.tasks != store.tasks {
            try persistence.save(candidate.tasks)
            store = candidate
        }
        return result
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
