import Foundation

public struct Tile: Equatable, Hashable, Sendable {
    public var letter: String
    public var value: Int
    public var bonus: String?

    public init(letter: String, value: Int, bonus: String? = nil) {
        self.letter = letter
        self.value = value
        self.bonus = bonus
    }
}

public struct ScoreSample: Equatable, Sendable {
    public var score: Int
    public var ratingX10: Int
    public var wordsEncoding: UInt64?
    public var isSynthetic: Bool

    public init(score: Int, ratingX10: Int, wordsEncoding: UInt64? = nil, isSynthetic: Bool = false) {
        self.score = score
        self.ratingX10 = ratingX10
        self.wordsEncoding = wordsEncoding
        self.isSynthetic = isSynthetic
    }
}

public struct Match: Equatable, Sendable {
    public var tiles: [Tile]
    public var scoreSamples: [ScoreSample]

    public init(tiles: [Tile], scoreSamples: [ScoreSample]) {
        self.tiles = tiles
        self.scoreSamples = scoreSamples
    }
}

