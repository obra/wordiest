import CoreGraphics
import XCTest
@testable import Wordiest

final class DragMathTests: XCTestCase {
    func testDraggedCenterXSubtractsTouchOffset() {
        // Touch is 30pt to the right of the tile center.
        XCTAssertEqual(DragMath.draggedCenterX(touchX: 140, touchOffsetX: 30), 110)
    }
}

