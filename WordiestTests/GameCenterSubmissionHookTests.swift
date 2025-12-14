import XCTest
@testable import Wordiest

@MainActor
final class GameCenterSubmissionHookTests: XCTestCase {
    private final class FakeGameCenter: GameCenterSubmitting {
        var lastSubmissions: [GameCenterScoreSubmission]?

        func submit(scoreSubmissions: [GameCenterScoreSubmission]) {
            lastSubmissions = scoreSubmissions
        }
    }

    func testAppModelSubmitsExpectedScoresAfterMatch() {
        let suiteName = "GameCenterSubmissionHookTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(defaults: defaults)
        settings.cumulativeScore = 1234

        let fake = FakeGameCenter()
        let model = AppModel(settings: settings, historyStore: HistoryStore(), gameCenter: fake)

        model.submitLeaderboardsAfterMatch(playerScore: 108, newRating: 57.3)

        XCTAssertEqual(
            fake.lastSubmissions,
            GameCenterLeaderboards.scoreSubmissions(
                cumulativeScore: 1234,
                bestRoundScore: 108,
                rating: 57.3
            )
        )
    }
}

