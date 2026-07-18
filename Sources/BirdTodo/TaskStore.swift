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

final class TaskStore {
    private(set) var tasks: [Task] = []

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
