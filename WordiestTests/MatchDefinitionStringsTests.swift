import XCTest
@testable import Wordiest

final class MatchDefinitionStringsTests: XCTestCase {
    func testDefinitionTextIncludesWordPointsAndSee() {
        XCTAssertEqual(
            MatchStrings.definitionText(word: "aardvark", points: 2, seeWord: "foobar", definition: "A nocturnal animal."),
            "AARDVARK (2 pts), see FOOBAR: A nocturnal animal."
        )
    }
}
