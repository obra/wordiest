import XCTest
@testable import Wordiest

final class PrettyRelativeTimeTests: XCTestCase {
    func testMomentsAgo() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let past = now.addingTimeInterval(-10)
        XCTAssertEqual(PrettyRelativeTime.format(target: past, relativeTo: now), "moments ago")
    }

    func testHoursAgo() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let past = now.addingTimeInterval(-3 * 3600)
        XCTAssertEqual(PrettyRelativeTime.format(target: past, relativeTo: now), "3 hours ago")
    }

    func testInMinutes() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let future = now.addingTimeInterval(2 * 60)
        XCTAssertEqual(PrettyRelativeTime.format(target: future, relativeTo: now), "in 2 minutes")
    }
}

