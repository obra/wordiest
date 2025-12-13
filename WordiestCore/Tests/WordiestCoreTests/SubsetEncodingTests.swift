import XCTest
@testable import WordiestCore

final class SubsetEncodingTests: XCTestCase {
    func testDecodeNibbleStreamIntoTileIndices() throws {
        // nibble stream: 1,2,3, F, 4,5  (1-based indices)
        let encoded: UInt64 = 0x123F45
        let decoded = try SubsetEncoding.decode(encoded, tileCount: 14)
        XCTAssertEqual(decoded.word1, [0, 1, 2])
        XCTAssertEqual(decoded.word2, [3, 4])
    }
}

