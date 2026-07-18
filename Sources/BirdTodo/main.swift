import AppKit

let application = NSApplication.shared
let appDelegate = BirdTodoAppDelegate()

application.delegate = appDelegate
application.setActivationPolicy(.accessory)
application.run()
