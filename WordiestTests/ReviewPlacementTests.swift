import XCTest
import WordiestCore
@testable import Wordiest

final class ReviewPlacementTests: XCTestCase {
    func testRackStateFromEncodingDistributesRemainingTilesLikeGameScene() throws {
        let encoding = try SubsetEncoding.encode(word1: [0, 1, 2], word2: [3, 4])
        let state = try XCTUnwrap(ReviewPlacement.rackState(tileCount: 14, encoding: encoding))

        XCTAssertEqual(state.word1, [0, 1, 2])
        XCTAssertEqual(state.word2, [3, 4])

        // Remaining tiles 5...13 start in bank1; overflow moves from the end into bank2 (reversed).
        XCTAssertEqual(state.bank1, [5, 6, 7, 8, 9, 10, 11])
        XCTAssertEqual(state.bank2, [13, 12])
    }
}

