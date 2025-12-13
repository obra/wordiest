import XCTest
@testable import Wordiest

final class SparklineMathTests: XCTestCase {
    func testRatingMinMaxRoundsToTens() {
        let mm = SparklineMath.ratingMinMax(ratings: [50.1, 50.0, 61.9, 62.0, 41.0])
        XCTAssertEqual(mm.min, 40.0)
        XCTAssertEqual(mm.max, 70.0)
    }

    func testAbnormalDeltaDetection() {
        XCTAssertTrue(SparklineMath.isAbnormal(expectedDelta: 0.2, actualDelta: 0.31))
        XCTAssertFalse(SparklineMath.isAbnormal(expectedDelta: 0.2, actualDelta: 0.29))
    }
}

