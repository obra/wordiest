import Foundation

enum SparklineMath {
    static func ratingMinMax(ratings: [Double]) -> (min: Double, max: Double) {
        guard let first = ratings.first else { return (0, 100) }
        var minV = floor(first / 10.0) * 10.0
        var maxV = ceil(first / 10.0) * 10.0
        for rating in ratings {
            minV = min(minV, floor(rating / 10.0) * 10.0)
            maxV = max(maxV, ceil(rating / 10.0) * 10.0)
        }
        return (minV, maxV)
    }

    static func isAbnormal(expectedDelta: Double, actualDelta: Double) -> Bool {
        abs(expectedDelta - actualDelta) >= 0.1
    }
}

