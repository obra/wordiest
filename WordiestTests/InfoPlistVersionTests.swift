import XCTest
@testable import Wordiest

final class InfoPlistVersionTests: XCTestCase {
    func testInfoPlistHasValidVersionStrings() {
        let bundle = Bundle(for: AppModel.self)
        let shortVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildVersion = bundle.infoDictionary?["CFBundleVersion"] as? String

        XCTAssertNotNil(shortVersion)
        XCTAssertNotNil(buildVersion)
        XCTAssertFalse(shortVersion?.isEmpty ?? true)
        XCTAssertFalse(buildVersion?.isEmpty ?? true)

        XCTAssertTrue(isValidBundleVersion(shortVersion ?? ""))
        XCTAssertTrue(isValidBundleVersion(buildVersion ?? ""))
    }

    private func isValidBundleVersion(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard (1...3).contains(parts.count) else { return false }
        return parts.allSatisfy { part in
            !part.isEmpty && part.allSatisfy { $0.isNumber }
        }
    }
}

