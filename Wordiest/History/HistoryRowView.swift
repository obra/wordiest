import SwiftUI
import WordiestCore

struct HistoryRowView: View {
    var palette: ColorPalette
    var entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            summaryText()
                .foregroundStyle(palette.foreground)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            Text(relativeTimestampText())
                .foregroundStyle(palette.faded)
                .font(.footnote)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func summaryText() -> Text {
        let words = HistoryRowFormatter.wordsString(entry: entry) ?? ""
        let plural = entry.score == 1 ? "" : "s"
        let delta = Double(entry.newRatingX10 - entry.ratingX10) / 10.0
        let deltaText = String(format: "%+.1f", delta)
        let suffix = HistoryRowFormatter.isBest(entry: entry) ? "*" : ""
        return Text(words).bold() + Text(" (\(entry.score) pt\(plural), \(deltaText) rtg)\(suffix)")
    }

    private func relativeTimestampText() -> String {
        guard let date = HistoryRowFormatter.parseGMTTimestamp(entry.timestamp) else { return "" }
        return PrettyRelativeTime.format(target: date, relativeTo: Date())
    }
}

enum HistoryRowFormatter {
    static func parseGMTTimestamp(_ timestamp: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: timestamp)
    }

    static func wordsString(entry: HistoryEntry) -> String? {
        guard let tiles = HistoryJSON.decodeMatchTiles(entry.matchDataJSON) else { return nil }
        guard let decoded = try? SubsetEncoding.decode(entry.wordsEncoding, tileCount: tiles.count) else { return nil }
        let word1 = decoded.word1.map { tiles[$0].letter }.joined()
        let word2 = decoded.word2.map { tiles[$0].letter }.joined()
        if word1.isEmpty { return word2 }
        if word2.isEmpty { return word1 }
        return "\(word1) + \(word2)"
    }

    static func isBest(entry: HistoryEntry) -> Bool {
        guard let samples = HistoryJSON.decodeScoreSamples(entry.scoreListJSON) else { return false }
        for sample in samples where sample.score > entry.score {
            return false
        }
        return true
    }
}
