import Foundation
import Testing
@testable import Perch

@Suite("App preferences")
struct AppPreferencesTests {
    @Test("Reminder pause state persists")
    func reminderPauseStatePersists() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = AppPreferences(defaults: defaults)

        #expect(preferences.remindersPaused == false)

        preferences.remindersPaused = true

        #expect(AppPreferences(defaults: defaults).remindersPaused)
    }

    @Test("Onboarding completion persists")
    func onboardingCompletionPersists() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = AppPreferences(defaults: defaults)

        #expect(preferences.hasCompletedOnboarding == false)

        preferences.hasCompletedOnboarding = true

        #expect(AppPreferences(defaults: defaults).hasCompletedOnboarding)
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}
