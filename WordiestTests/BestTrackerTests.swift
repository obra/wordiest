import XCTest
@testable import Wordiest

final class BestTrackerTests: XCTestCase {
    func testTracksBestScoreAndRestoresWhenCurrentIsWorse() {
        let tracker = BestTracker()
        let stateA = RackState(word1: [0, 1], word2: [], bank1: [2, 3, 4], bank2: [5, 6, 7, 8, 9, 10, 11, 12, 13])
        let stateB = RackState(word1: [0], word2: [], bank1: [1, 2, 3, 4], bank2: [5, 6, 7, 8, 9, 10, 11, 12, 13])

        tracker.observe(state: stateA, bestScoreCandidate: 10)
        tracker.observe(state: stateB, bestScoreCandidate: 5)

        XCTAssertEqual(tracker.restoreIfBetterThanCurrent(currentScore: 5), stateA)
        XCTAssertNil(tracker.restoreIfBetterThanCurrent(currentScore: 10))
    }
}

