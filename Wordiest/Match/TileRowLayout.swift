import CoreGraphics

struct TileRowLayout {
    struct Metrics: Equatable {
        var tileSize: CGSize
        var gap: CGFloat
        var startX: CGFloat
        var tileCount: Int
    }

    static func metrics(baseTileSize: CGSize, baseGap: CGFloat, tileCount: Int, availableWidth: CGFloat, leftX: CGFloat) -> Metrics {
        let count = max(tileCount, 1)
        let neededWidth = (CGFloat(count) * baseTileSize.width) + (CGFloat(count - 1) * baseGap)
        let scale = min(1, availableWidth / neededWidth)

        let tileSize = CGSize(width: baseTileSize.width * scale, height: baseTileSize.height * scale)
        let gap = baseGap * scale
        let totalWidth = (CGFloat(count) * tileSize.width) + (CGFloat(count - 1) * gap)
        let startX = leftX + ((availableWidth - totalWidth) / 2) + (tileSize.width / 2)
        return Metrics(tileSize: tileSize, gap: gap, startX: startX, tileCount: count)
    }

    static func insertionIndex(dropX: CGFloat, metrics: Metrics) -> Int {
        let step = metrics.tileSize.width + metrics.gap
        let maxIndex = max(0, metrics.tileCount - 1)
        guard step > 0 else { return 0 }

        // We compute insertion based on midpoints between adjacent slot centers. The number of
        // boundaries crossed is the insertion index.
        //
        // This assumes `metrics` was calculated for the *final* tile count (existing + 1).
        if dropX < metrics.startX + (step * 0.5) {
            return 0
        }

        // Find the first boundary the drop point is left of.
        // With N slots there are (N-1) midpoints; since we don't know N here, callers should clamp.
        let raw = Int(floor((dropX - metrics.startX) / step + 0.5))
        return min(maxIndex, max(0, raw))
    }

    static func insert<T>(element: T, into existing: [T], dropX: CGFloat, metrics: Metrics) -> [T] {
        let idx = insertionIndex(dropX: dropX, metrics: metrics)
        var result = existing
        result.insert(element, at: min(existing.count, max(0, idx)))
        return result
    }
}
