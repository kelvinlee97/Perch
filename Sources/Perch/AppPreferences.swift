import Foundation

final class AppPreferences {
    private enum Key {
        static let remindersPaused = "remindersPaused"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var remindersPaused: Bool {
        get { defaults.bool(forKey: Key.remindersPaused) }
        set { defaults.set(newValue, forKey: Key.remindersPaused) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }
}
