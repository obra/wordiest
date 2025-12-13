import XCTest
@testable import Wordiest

final class DragScaleTests: XCTestCase {
    func testDraggingScaleMultiplierMatchesAndroid() {
        XCTAssertEqual(DragConstants.draggingScaleMultiplier, 1.25, accuracy: 0.0001)
    }
}

