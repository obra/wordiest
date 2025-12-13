import Foundation

public final class MatchDataStore: Sendable {
    public enum LoadError: Error {
        case missingHeader
        case invalidHeader
        case indexOutOfRange(Int)
        case invalidMatchJSON(Int)
    }

    private let data: Data
    private let firstOffset: Int
    private let endOffsets: [Int]

    public init(data: Data) throws {
        self.data = data

        guard let headerEnd = data.firstIndex(of: UInt8(ascii: "]")) else {
            throw LoadError.missingHeader
        }

        let headerData = data.prefix(headerEnd + 1)
        let parsed = try JSONSerialization.jsonObject(with: Data(headerData))
        guard let headerArray = parsed as? [Int], !headerArray.isEmpty else {
            throw LoadError.invalidHeader
        }

        self.firstOffset = headerEnd + 1
        self.endOffsets = headerArray
    }

    public var count: Int { endOffsets.count }

    public func match(at index: Int) throws -> Match {
        guard index >= 0, index < endOffsets.count else {
            throw LoadError.indexOutOfRange(index)
        }

        let prev = index > 0 ? endOffsets[index - 1] : 0
        let end = endOffsets[index]
        let start = firstOffset + prev
        let length = end - prev

        let slice = data.subdata(in: start..<(start + length))
        guard let root = try? JSONSerialization.jsonObject(with: slice) as? [String: Any] else {
            throw LoadError.invalidMatchJSON(index)
        }

        let tiles = try parseTiles(root)
        let samples = parseScoreSamples(root)
        return Match(tiles: tiles, scoreSamples: samples)
    }

    private func parseTiles(_ root: [String: Any]) throws -> [Tile] {
        guard let tileArray = root["i"] as? [[String: Any]] else {
            throw LoadError.invalidMatchJSON(-1)
        }
        return tileArray.map { obj in
            let letter = (obj["l"] as? String) ?? ""
            let value = (obj["x"] as? Int) ?? 0
            let bonus = obj["b"] as? String
            return Tile(letter: letter, value: value, bonus: bonus)
        }
    }

    private func parseScoreSamples(_ root: [String: Any]) -> [ScoreSample] {
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
}

