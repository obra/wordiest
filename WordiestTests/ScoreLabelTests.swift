import XCTest
@testable import Wordiest

final class ScoreLabelTests: XCTestCase {
    func testTotalScoreFormattingAndPluralization() {
        XCTAssertEqual(MatchStrings.totalScore(1), "Total 1 point")
        XCTAssertEqual(MatchStrings.totalScore(2), "Total 2 points")
    }

    func testTotalScoreWithBestSuffix() {
        XCTAssertEqual(MatchStrings.totalScoreWithBest(10, best: 12), "Total 10 points (best 12)")
        XCTAssertEqual(MatchStrings.totalScoreWithBest(12, best: 12), "Total 12 points")
    }
}

