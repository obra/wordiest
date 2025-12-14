import XCTest
@testable import Wordiest

final class GameCenterLeaderboardsTests: XCTestCase {
    func testScoreSubmissionsIncludeTotalBestAndRoundedRatingPercent() {
        let submissions = GameCenterLeaderboards.scoreSubmissions(
            cumulativeScore: 1234,
            bestRoundScore: 108,
            rating: 57.3
        )

        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: submissions.map { ($0.leaderboardID, $0.score) }),
            [
                GameCenterLeaderboards.totalPointsAllTimeID: 1234,
                GameCenterLeaderboards.bestRoundScoreID: 108,
                GameCenterLeaderboards.ratingPercentID: 57,
            ]
        )
    }

    func testRatingRoundingHalfUp() {
        let submissions = GameCenterLeaderboards.scoreSubmissions(
            cumulativeScore: 0,
            bestRoundScore: 0,
            rating: 57.5
        )
        let rating = submissions.first(where: { $0.leaderboardID == GameCenterLeaderboards.ratingPercentID })
        XCTAssertEqual(rating?.score, 58)
    }
}

