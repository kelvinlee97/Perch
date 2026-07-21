import Foundation
import Darwin

final class SingleInstanceLock {
    private var fileDescriptor: Int32 = -1

    deinit {
        if fileDescriptor >= 0 {
            close(fileDescriptor)
        }
    }

    func acquire() -> Bool {
        do {
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("BirdTodo", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let lockURL = directory.appendingPathComponent("instance.lock")
            let descriptor = open(lockURL.path, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
            guard descriptor >= 0 else { return false }
            guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
                close(descriptor)
                return false
            }

            fileDescriptor = descriptor
            return true
        } catch {
            return false
        }
    }
}
