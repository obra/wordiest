import Foundation

enum RepoPaths {
    static func repoRootURL(fromFile filePath: String = #filePath) -> URL {
        var url = URL(fileURLWithPath: filePath)
        // .../WordiestCore/Tests/WordiestCoreTests/<file>.swift
        url.deleteLastPathComponent() // <file>.swift -> WordiestCoreTests
        url.deleteLastPathComponent() // WordiestCoreTests
        url.deleteLastPathComponent() // Tests
        url.deleteLastPathComponent() // WordiestCore
        return url
    }
}
