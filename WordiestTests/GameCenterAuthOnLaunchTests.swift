import XCTest
@testable import Wordiest

@MainActor
final class GameCenterAuthOnLaunchTests: XCTestCase {
    private final class FakeGameCenter: GameCenterSubmitting {
        var authenticateCount = 0

        func authenticateIfNeeded() {
            authenticateCount += 1
        }

        func submit(scoreSubmissions: [GameCenterScoreSubmission]) {}
    }

    func testAppModelAuthenticatesGameCenterOnInit() {
        let fake = FakeGameCenter()
        _ = AppModel(settings: AppSettings(defaults: .standard), historyStore: HistoryStore(), gameCenter: fake)
        XCTAssertEqual(fake.authenticateCount, 1)
    }
}

