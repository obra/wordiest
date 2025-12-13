import XCTest
@testable import Wordiest

final class ResetTests: XCTestCase {
    func testResetTapClearsBothWords() {
        let state = RackState(word1: [0, 1], word2: [2], bank1: [3], bank2: [4, 5])

        let reset = Reset.apply(
            state: state,
            clearOnlyInvalid: false,
            isWord1Valid: true,
            isWord2Valid: true,
            shuffle: { _ in XCTFail("unexpected shuffle"); return state }
        )

        XCTAssertEqual(reset.word1, [])
        XCTAssertEqual(reset.word2, [])
        XCTAssertEqual(Set(reset.bank1 + reset.bank2), Set<Int>([0, 1, 2, 3, 4, 5]))
    }

    func testResetLongPressClearsOnlyInvalidWords() {
        let state = RackState(word1: [0, 1], word2: [2], bank1: [3], bank2: [4, 5])

        let reset = Reset.apply(
            state: state,
            clearOnlyInvalid: true,
            isWord1Valid: false,
            isWord2Valid: true,
            shuffle: { _ in XCTFail("unexpected shuffle"); return state }
        )

        XCTAssertEqual(reset.word1, [])
        XCTAssertEqual(reset.word2, [2])
        XCTAssertEqual(Set(reset.bank1 + reset.bank2), Set<Int>([0, 1, 3, 4, 5]))
    }

    func testResetLongPressShufflesIfNothingCleared() {
        let state = RackState(word1: [0], word2: [], bank1: [1, 2], bank2: [3, 4, 5])

        let shuffled = RackState(word1: [0], word2: [], bank1: [2, 1, 5], bank2: [4, 3])

        let reset = Reset.apply(
            state: state,
            clearOnlyInvalid: true,
            isWord1Valid: true,
            isWord2Valid: true,
            shuffle: { _ in shuffled }
        )

        XCTAssertEqual(reset, shuffled)
    }
}
