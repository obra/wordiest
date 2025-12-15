import XCTest
@testable import Wordiest

final class ThemeModeTests: XCTestCase {
    func testDefaultThemeModeIsSystem() async {
        let suiteName = "ThemeModeTests.\(UUID().uuidString)"
        let themeMode = await MainActor.run { () -> AppSettings.ThemeMode in
            let defaults = UserDefaults(suiteName: suiteName)!
            defer { defaults.removePersistentDomain(forName: suiteName) }
            let settings = AppSettings(defaults: defaults)
            return settings.themeMode
        }
        XCTAssertEqual(themeMode, .system)
    }

    func testThemeModePersistsToDefaults() async {
        let suiteName = "ThemeModeTests.\(UUID().uuidString)"
        let restoredThemeMode = await MainActor.run { () -> AppSettings.ThemeMode in
            let defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)
            let settings = AppSettings(defaults: defaults)
            settings.themeMode = .dark
            let restored = AppSettings(defaults: defaults)
            defaults.removePersistentDomain(forName: suiteName)
            return restored.themeMode
        }
        XCTAssertEqual(restoredThemeMode, .dark)
    }
}
