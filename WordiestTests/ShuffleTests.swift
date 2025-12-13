import XCTest
@testable import Wordiest

final class ShuffleTests: XCTestCase {
    func testShuffleOnlyPermutesBanksAndKeepsWords() {
        let state = RackState(
            word1: [100],
            word2: [200],
            bank1: [0, 1, 2],
            bank2: [3, 4]
        )

        let shuffled = Shuffle.shuffled(state: state, randomIndex: { upperBound in
            // Force the initial shuffle to be a no-op. The algorithm should still avoid a full no-op.
            upperBound - 1
        })

        XCTAssertEqual(shuffled.word1, state.word1)
        XCTAssertEqual(shuffled.word2, state.word2)

        XCTAssertEqual(Set(shuffled.bank1 + shuffled.bank2), Set(state.bank1 + state.bank2))
        XCTAssertEqual(shuffled.bank1.count, (state.bank1.count + state.bank2.count + 1) / 2)

        XCTAssertNotEqual(shuffled.bank1 + shuffled.bank2, state.bank1 + state.bank2)
    }
}

