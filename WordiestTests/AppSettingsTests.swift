import XCTest
@testable import Wordiest

final class AppSettingsTests: XCTestCase {
    func testResetRatingAndStatsPreservesThemeModeAndSoundAndUserId() async {
        let suiteName = "AppSettingsTests.\(UUID().uuidString)"

        struct Snapshot: Equatable {
            var themeMode: AppSettings.ThemeMode
            var soundEnabled: Bool
            var originalUserId: UInt64
            var currentUserId: UInt64
            var rating: Double
            var ratingDeviation: Double
            var numMatches: Int
            var cumulativeScore: Int64
        }

        let snapshot = await MainActor.run { () -> Snapshot in
            let defaults = UserDefaults(suiteName: suiteName)!
            defer { defaults.removePersistentDomain(forName: suiteName) }

            let settings = AppSettings(defaults: defaults)
            let originalUserId = settings.userId

            settings.themeMode = .dark
            settings.soundEnabled = false
            settings.rating = 12.3
            settings.ratingDeviation = 9.9
            settings.numMatches = 123
            settings.cumulativeScore = 456

            settings.resetRatingAndStats()

            return Snapshot(
                themeMode: settings.themeMode,
                soundEnabled: settings.soundEnabled,
                originalUserId: originalUserId,
                currentUserId: settings.userId,
                rating: settings.rating,
                ratingDeviation: settings.ratingDeviation,
                numMatches: settings.numMatches,
                cumulativeScore: settings.cumulativeScore
            )
        }

        XCTAssertEqual(snapshot.themeMode, .dark)
        XCTAssertFalse(snapshot.soundEnabled)
        XCTAssertNotEqual(snapshot.currentUserId, 0)
        XCTAssertEqual(snapshot.currentUserId, snapshot.originalUserId)

        XCTAssertEqual(snapshot.rating, 50.0)
        XCTAssertEqual(snapshot.ratingDeviation, 0.0)
        XCTAssertEqual(snapshot.numMatches, 0)
        XCTAssertEqual(snapshot.cumulativeScore, 0)
    }
}
