import XCTest
@testable import Wordiest

final class ScoreCelebrateTests: XCTestCase {
    func testShouldCelebrateRequiresOpponentsAndZeroLosses() {
        XCTAssertFalse(ScoreSummary.shouldCelebrate(opponentsCount: 0, expectedLosses: 0, upsetLosses: 0))
        XCTAssertFalse(ScoreSummary.shouldCelebrate(opponentsCount: 10, expectedLosses: 1, upsetLosses: 0))
        XCTAssertFalse(ScoreSummary.shouldCelebrate(opponentsCount: 10, expectedLosses: 0, upsetLosses: 1))
        XCTAssertTrue(ScoreSummary.shouldCelebrate(opponentsCount: 10, expectedLosses: 0, upsetLosses: 0))
    }
}

