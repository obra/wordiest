import XCTest
@testable import Wordiest

final class ScoreSummaryTests: XCTestCase {
    func testScoreSummaryPluralization() {
        XCTAssertEqual(ScoreSummary.scoreText(score: 1, percentile: 50), "You scored 1 point, beating 50% of other players.")
        XCTAssertEqual(ScoreSummary.scoreText(score: 2, percentile: 50), "You scored 2 points, beating 50% of other players.")
    }

    func testRatingSummaryGainLossNone() {
        XCTAssertEqual(ScoreSummary.ratingText(old: 50.0, new: 51.2, matchCount: 5), "Your 50.0 rating grew by 1.2 to 51.2!")
        XCTAssertEqual(ScoreSummary.ratingText(old: 50.0, new: 48.8, matchCount: 5), "Your 50.0 rating fell by 1.2 to 48.8.")
        XCTAssertEqual(ScoreSummary.ratingText(old: 50.0, new: 50.0, matchCount: 5), "No rating change, still 50.0.")
        XCTAssertEqual(ScoreSummary.ratingText(old: 0.0, new: 50.0, matchCount: 0), "Your new rating is 50.0!")
    }
}

