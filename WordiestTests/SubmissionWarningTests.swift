import XCTest
@testable import Wordiest

final class SubmissionWarningTests: XCTestCase {
    func testWarningMessageForValidWordCount() {
        XCTAssertEqual(SubmissionWarning.message(validWordCount: 0), "Submit no words?")
        XCTAssertEqual(SubmissionWarning.message(validWordCount: 1), "Submit only one word?")
        XCTAssertEqual(SubmissionWarning.message(validWordCount: 2), "Submit these words?")
    }
}

