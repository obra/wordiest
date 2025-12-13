import CoreGraphics

enum ScoreGraphMath {
    static func recomputeMinMaxEvenlyFromCenter(_ values: [Double], center: Double) -> Double {
        if values.isEmpty { return 0.0 }

        let sorted = values.sorted()
        let low = sorted[sorted.count / 8]
        let high = sorted[(sorted.count * 7) / 8]

        let pad = (high - low) * 1.5
        let paddedLow = low - pad
        let paddedHigh = high + pad

        let clampedLow = max(paddedLow, sorted.first ?? low)
        let clampedHigh = min(paddedHigh, sorted.last ?? high)

        return max(abs(clampedLow - center), abs(clampedHigh - center))
    }

    static func minMax(center: Double, span: Double) -> (min: Double, max: Double) {
        (center - span, center + span)
    }

    static func mapX(value: Double, min: Double, max: Double, rect: CGRect) -> CGFloat {
        if value <= min { return rect.minX }
        if value >= max { return rect.maxX }
        let span = max - min
        if span == 0 { return 0 }
        return rect.minX + rect.width * CGFloat((value - min) / span)
    }

    static func mapY(value: Double, min: Double, max: Double, rect: CGRect) -> CGFloat {
        if value <= min { return rect.maxY }
        if value >= max { return rect.minY }
        let span = max - min
        if span == 0 { return 0 }
        return rect.minY + rect.height * (1.0 - CGFloat((value - min) / span))
    }

    static func mappedPoints(points: [CGPoint], center: CGPoint, rect: CGRect) -> (mapped: [CGPoint], minX: Double, maxX: Double, minY: Double, maxY: Double) {
        let xValues = [Double(center.x)] + points.map { Double($0.x) }
        let yValues = [Double(center.y)] + points.map { Double($0.y) }

        let xSpan = recomputeMinMaxEvenlyFromCenter(xValues, center: Double(center.x))
        let ySpan = recomputeMinMaxEvenlyFromCenter(yValues, center: Double(center.y))

        let xMinMax = minMax(center: Double(center.x), span: xSpan)
        let yMinMax = minMax(center: Double(center.y), span: ySpan)

        let mapped = points.map { p in
            CGPoint(
                x: mapX(value: Double(p.x), min: xMinMax.min, max: xMinMax.max, rect: rect),
                y: mapY(value: Double(p.y), min: yMinMax.min, max: yMinMax.max, rect: rect)
            )
        }

        return (mapped, xMinMax.min, xMinMax.max, yMinMax.min, yMinMax.max)
    }

    static func nearestPointIndex(inScreenSpace location: CGPoint, mappedPoints: [CGPoint]) -> Int? {
        if mappedPoints.isEmpty { return nil }
        var bestIndex = 0
        var bestDist = CGFloat.greatestFiniteMagnitude
        for (idx, p) in mappedPoints.enumerated() {
            let dx = p.x - location.x
            let dy = p.y - location.y
            let dist = dx * dx + dy * dy
            if dist < bestDist {
                bestDist = dist
                bestIndex = idx
            }
        }
        return bestIndex
    }
}

