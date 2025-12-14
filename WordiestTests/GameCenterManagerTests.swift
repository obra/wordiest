import XCTest
@testable import Wordiest

@MainActor
final class GameCenterManagerTests: XCTestCase {
    private final class FakeClient: GameCenterClient {
        var isAuthenticated: Bool
        var reported: [GameCenterScoreSubmission] = []

        init(isAuthenticated: Bool) {
            self.isAuthenticated = isAuthenticated
        }

        func authenticate(present: @escaping (UIViewController) -> Void) {}

        func report(scores: [GameCenterScoreSubmission]) {
            reported.append(contentsOf: scores)
        }
    }

    func testDoesNotReportScoresWhenNotAuthenticated() {
        let client = FakeClient(isAuthenticated: false)
        let manager = GameCenterManager(client: client)

        manager.submit(scoreSubmissions: [
            GameCenterScoreSubmission(leaderboardID: "a", score: 1),
        ])

        XCTAssertTrue(client.reported.isEmpty)
    }

    func testReportsScoresWhenAuthenticated() {
        let client = FakeClient(isAuthenticated: true)
        let manager = GameCenterManager(client: client)

        let submissions = [
            GameCenterScoreSubmission(leaderboardID: "a", score: 1),
            GameCenterScoreSubmission(leaderboardID: "b", score: 2),
        ]
        manager.submit(scoreSubmissions: submissions)

        XCTAssertEqual(client.reported, submissions)
    }
}
