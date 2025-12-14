import CoreGraphics
import XCTest
@testable import Wordiest

final class MatchVerticalLayoutTests: XCTestCase {
    func testCentersMatchAndroidGapStructure() {
        let centers = MatchVerticalLayout.centers(
            containerHeight: 800,
            topInset: 40,
            bottomInset: 20,
            spacer: 16,
            scoreAreaHeight: 40,
            word1Height: 70,
            word2Height: 70,
            bank1Height: 70,
            bank2Height: 70
        )

        // Banks use fixed spacer separation and bottom spacer.
        let bankGap = centers.bank1 - centers.bank2
        XCTAssertEqual(bankGap, 70 + 16, accuracy: 0.001)

        // The gap between bank1 and word2 equals the gap between word2 and word1.
        let bank1Top = centers.bank1 + 35
        let word2Bottom = centers.word2 - 35
        let word2Top = centers.word2 + 35
        let word1Bottom = centers.word1 - 35

        XCTAssertEqual(Double(word2Bottom - bank1Top), Double(word1Bottom - word2Top), accuracy: 0.001)
    }
}
