import XCTest
@testable import WordiestCore

final class ScoringTests: XCTestCase {
    func testScoresTwoWordMoveFromKnownMatch() throws {
        // Tiles from match #0 in assets/matchdata.packed
        let tiles: [Tile] = [
            .init(letter: "h", value: 3),
            .init(letter: "r", value: 1),
            .init(letter: "i", value: 1, bonus: "5l"),
            .init(letter: "e", value: 1),
            .init(letter: "q", value: 10),
            .init(letter: "e", value: 1),
            .init(letter: "s", value: 1),
            .init(letter: "e", value: 1),
            .init(letter: "r", value: 1, bonus: "4l"),
            .init(letter: "g", value: 3),
            .init(letter: "h", value: 3),
            .init(letter: "r", value: 1),
            .init(letter: "u", value: 2),
            .init(letter: "e", value: 1),
        ]

        let higher: [Tile] = [tiles[0], tiles[2], tiles[9], tiles[10], tiles[3], tiles[1]]
        let queerer: [Tile] = [tiles[4], tiles[12], tiles[5], tiles[7], tiles[8], tiles[13], tiles[11]]

        XCTAssertEqual(try WordiestScoring.scoreWord(higher), 16)
        XCTAssertEqual(try WordiestScoring.scoreWord(queerer), 20)
        XCTAssertEqual(try WordiestScoring.scoreMove(word1: higher, word2: queerer), 36)
    }

    func testRejectsUnknownBonusType() {
        XCTAssertThrowsError(try WordiestScoring.scoreWord([.init(letter: "a", value: 1, bonus: "2x")]))
    }
}

