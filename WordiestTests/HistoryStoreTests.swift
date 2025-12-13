import XCTest
@testable import Wordiest

@MainActor
final class HistoryStoreTests: XCTestCase {
    func testAppendKeepsNewestFirst() {
        let url = tempFileURL()
        let store = HistoryStore(fileURL: url, maxEntries: 100)

        store.append(makeEntry(matchId: "a", timestamp: "2025-01-01 00:00:00"))
        store.append(makeEntry(matchId: "b", timestamp: "2025-01-01 00:00:01"))

        XCTAssertEqual(store.entries.map(\.matchId), ["b", "a"])
    }

    func testCapacityTrimsOldestBeyondLimit() {
        let url = tempFileURL()
        let store = HistoryStore(fileURL: url, maxEntries: 2)

        store.append(makeEntry(matchId: "a", timestamp: "2025-01-01 00:00:00"))
        store.append(makeEntry(matchId: "b", timestamp: "2025-01-01 00:00:01"))
        store.append(makeEntry(matchId: "c", timestamp: "2025-01-01 00:00:02"))

        XCTAssertEqual(store.entries.map(\.matchId), ["c", "b"])
    }

    func testDeleteRemovesEntry() {
        let url = tempFileURL()
        let store = HistoryStore(fileURL: url, maxEntries: 100)

        let entry = makeEntry(matchId: "a", timestamp: "2025-01-01 00:00:00")
        store.append(entry)
        store.delete(id: entry.id)

        XCTAssertEqual(store.entries.count, 0)
    }

    func testPersistenceRoundTrips() {
        let url = tempFileURL()

        do {
            let store = HistoryStore(fileURL: url, maxEntries: 100)
            store.append(makeEntry(matchId: "a", timestamp: "2025-01-01 00:00:00"))
            store.append(makeEntry(matchId: "b", timestamp: "2025-01-01 00:00:01"))
        }

        let reloaded = HistoryStore(fileURL: url, maxEntries: 100)
        XCTAssertEqual(reloaded.entries.map(\.matchId), ["b", "a"])
    }

    private func makeEntry(matchId: String, timestamp: String) -> HistoryEntry {
        HistoryEntry(
            matchId: matchId,
            matchDataJSON: "{\"i\":[]}",
            scoreListJSON: "{\"sl\":[]}",
            wordsEncoding: 0,
            score: 0,
            ratingX10: 500,
            newRatingX10: 500,
            percentileX10: 1000,
            timestamp: timestamp
        )
    }

    private func tempFileURL(file: StaticString = #filePath, line: UInt = #line) -> URL {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        } catch {
            XCTFail("failed to create temp dir: \(error)", file: file, line: line)
        }
        return base.appendingPathComponent("history.json")
    }
}
