import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []

    private let fileURL: URL
    private let maxEntries: Int

    init(fileURL: URL = HistoryStore.defaultFileURL(), maxEntries: Int = 100) {
        self.fileURL = fileURL
        self.maxEntries = maxEntries
        loadFromDisk()
    }

    func append(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
        saveToDisk()
    }

    func delete(id: HistoryEntry.ID) {
        entries.removeAll { $0.id == id }
        saveToDisk()
    }

    func clear() {
        entries.removeAll(keepingCapacity: false)
        saveToDisk()
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(entries) else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Ignore persistence failures; game remains playable.
        }
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("wordiest-history.json")
    }
}

