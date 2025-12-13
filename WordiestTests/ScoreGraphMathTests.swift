import XCTest
@testable import Wordiest

final class ScoreGraphMathTests: XCTestCase {
    func testRecomputeMinMaxEvenlyFromCenterMatchesAndroidShape() {
        let values: [Double] = [50, 49, 51, 60, 40, 55, 45, 48, 52]
        let span = ScoreGraphMath.recomputeMinMaxEvenlyFromCenter(values, center: 50)
        XCTAssertGreaterThan(span, 0)
        XCTAssertEqual(ScoreGraphMath.minMax(center: 50, span: span).min, 50 - span)
    }
}

