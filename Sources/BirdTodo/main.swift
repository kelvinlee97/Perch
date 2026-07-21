import AppKit

let instanceLock = SingleInstanceLock()
guard instanceLock.acquire() else {
    exit(EXIT_SUCCESS)
}

let application = NSApplication.shared
let appDelegate = BirdTodoAppDelegate()

application.delegate = appDelegate
application.setActivationPolicy(.accessory)
application.run()
