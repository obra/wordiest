import Foundation

public struct UpdateRating: Sendable {
    public struct ScoreRating: Sendable {
        public var score: Int
        public var rating: Double
        public var wordsEncoding: UInt64?

        public init(score: Int, rating: Double, wordsEncoding: UInt64?) {
            self.score = score
            self.rating = rating
            self.wordsEncoding = wordsEncoding
        }
    }

    private static let alpha: Double = 0.2

    public private(set) var rating: Double
    public private(set) var ratingDeviation: Double

    public private(set) var upsetWins: Int = 0
    public private(set) var expectedLosses: Int = 0
    public private(set) var expectedWins: Int = 0
    public private(set) var upsetLosses: Int = 0
    public private(set) var percentile: Double = 0.0
    public private(set) var newRating: Double = 0.0

    public init(rating: Double, ratingDeviation: Double) {
        self.rating = rating
        self.ratingDeviation = ratingDeviation
        self.newRating = rating
    }

    public static func ceilTenths(_ value: Double) -> Double {
        (ceil(value * 10.0)) / 10.0
    }

    public mutating func update(playerScore: Int, opponents: [ScoreRating]) {
        upsetWins = 0
        expectedLosses = 0
        expectedWins = 0
        upsetLosses = 0

        for opponent in opponents {
            if opponent.score > playerScore {
                if opponent.rating < rating {
                    upsetLosses += 1
                } else {
                    expectedLosses += 1
                }
            } else if opponent.rating < rating {
                expectedWins += 1
            } else {
                upsetWins += 1
            }
        }

        if opponents.isEmpty {
            percentile = 100.0
        } else {
            percentile = (Double(expectedWins + upsetWins) * 100.0) / Double(opponents.count)
        }
        percentile = Self.ceilTenths(percentile)

        newRating = (percentile * Self.alpha) + (rating * 0.8)
        newRating = Self.ceilTenths(newRating)
        rating = newRating
    }
}

