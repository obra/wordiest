import Foundation
import WordiestCore

enum HistoryJSON {
    static func encodeMatchTiles(_ tiles: [Tile]) -> String {
        let array: [[String: Any]] = tiles.map { tile in
            var obj: [String: Any] = [
                "l": tile.letter,
                "x": tile.value,
            ]
            if let bonus = tile.bonus {
                obj["b"] = bonus
            }
            return obj
        }
        return encodeJSON(["i": array])
    }

    static func encodeScoreSamples(_ samples: [ScoreSample]) -> String {
        let array: [[String: Any]] = samples.map { s in
            var obj: [String: Any] = [
                "s": s.score,
                "r": s.ratingX10,
                "a": s.isSynthetic,
            ]
            if let w = s.wordsEncoding {
                obj["w"] = NSNumber(value: w)
            }
            return obj
        }
        return encodeJSON(["sl": array])
    }

    static func decodeMatchTiles(_ json: String) -> [Tile]? {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        guard let tilesArray = root["i"] as? [[String: Any]] else { return nil }
        return tilesArray.map { obj in
            Tile(
                letter: (obj["l"] as? String) ?? "",
                value: (obj["x"] as? Int) ?? 0,
                bonus: obj["b"] as? String
            )
        }
    }

    static func decodeScoreSamples(_ json: String) -> [ScoreSample]? {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        guard let array = root["sl"] as? [[String: Any]] else { return [] }
        return array.map { obj in
            let score = (obj["s"] as? Int) ?? 0
            let ratingX10 = (obj["r"] as? Int) ?? 0
            let isSynthetic = (obj["a"] as? Bool) ?? false

            let wordsEncoding: UInt64?
            if let num = obj["w"] as? NSNumber {
                wordsEncoding = num.uint64Value
            } else {
                wordsEncoding = nil
            }

            return ScoreSample(score: score, ratingX10: ratingX10, wordsEncoding: wordsEncoding, isSynthetic: isSynthetic)
        }
    }

    static func gmtTimestampNow(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func encodeJSON(_ value: Any) -> String {
        guard JSONSerialization.isValidJSONObject(value) else { return "{}" }
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: []) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
