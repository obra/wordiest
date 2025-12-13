import XCTest
@testable import WordiestCore

final class DefinitionsTests: XCTestCase {
    func testKnownWordHasDefinition() throws {
        let repoRoot = RepoPaths.repoRootURL()
        let idxURL = repoRoot.appendingPathComponent("Wordiest/Resources/words.idx")
        let defURL = repoRoot.appendingPathComponent("Wordiest/Resources/words.def")
        let defs = Definitions(indexData: try Data(contentsOf: idxURL), definitionsData: try Data(contentsOf: defURL))

        let definition = try defs.definition(for: "aardvark")
        XCTAssertNotNil(definition)
        XCTAssertFalse(definition?.definition.isEmpty ?? true)
    }

    func testUnknownWordIsNil() throws {
        let repoRoot = RepoPaths.repoRootURL()
        let idxURL = repoRoot.appendingPathComponent("Wordiest/Resources/words.idx")
        let defURL = repoRoot.appendingPathComponent("Wordiest/Resources/words.def")
        let defs = Definitions(indexData: try Data(contentsOf: idxURL), definitionsData: try Data(contentsOf: defURL))

        XCTAssertNil(try defs.definition(for: "zzzzzzzz"))
    }
}

