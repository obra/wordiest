import XCTest
@testable import WordiestCore

final class MatchDataStoreTests: XCTestCase {
    func testLoadsFirstMatchTiles() throws {
        let repoRoot = RepoPaths.repoRootURL()
        let url = repoRoot.appendingPathComponent("Wordiest/Resources/matchdata.packed")
        let data = try Data(contentsOf: url)

        let store = try MatchDataStore(data: data)
        XCTAssertEqual(store.count, 1999)

        let match0 = try store.match(at: 0)
        XCTAssertEqual(match0.tiles.count, 14)

        XCTAssertEqual(match0.tiles.map(\.letter), ["h", "r", "i", "e", "q", "e", "s", "e", "r", "g", "h", "r", "u", "e"])
        XCTAssertEqual(match0.tiles.map(\.value), [3, 1, 1, 1, 10, 1, 1, 1, 1, 3, 3, 1, 2, 1])
        XCTAssertEqual(match0.tiles[2].bonus?.lowercased(), "5l")
        XCTAssertEqual(match0.tiles[8].bonus?.lowercased(), "4l")
        XCTAssertFalse(match0.scoreSamples.isEmpty)
    }
}

