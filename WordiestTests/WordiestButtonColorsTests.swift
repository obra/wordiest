import XCTest
@testable import Wordiest

final class WordiestButtonColorsTests: XCTestCase {
    func testBackgroundColorMatchesAndroidStateList() {
        let palette = ColorPalette.palette(index: 1)
        XCTAssertEqual(WordiestButtonColors.backgroundUIColor(palette: palette, isPressed: false), palette.uiBackground)
        XCTAssertEqual(WordiestButtonColors.backgroundUIColor(palette: palette, isPressed: true), palette.uiFaded)
    }
}

