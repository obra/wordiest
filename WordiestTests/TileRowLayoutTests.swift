import CoreGraphics
import XCTest
@testable import Wordiest

final class TileRowLayoutTests: XCTestCase {
    func testInsertionIndexUsesDropXRatherThanAlwaysAppending() {
        let baseTileSize = CGSize(width: 60, height: 66)
        let gap: CGFloat = 10
        let availableWidth: CGFloat = 320
        let leftX: CGFloat = 0

        // Existing row has 4 tiles; after drop there will be 5.
        let metrics = TileRowLayout.metrics(
            baseTileSize: baseTileSize,
            baseGap: gap,
            tileCount: 5,
            availableWidth: availableWidth,
            leftX: leftX
        )

        let step = metrics.tileSize.width + metrics.gap
        XCTAssertEqual(TileRowLayout.insertionIndex(dropX: metrics.startX - 100, metrics: metrics), 0)
        XCTAssertEqual(TileRowLayout.insertionIndex(dropX: metrics.startX + (step * 0.49), metrics: metrics), 0)
        XCTAssertEqual(TileRowLayout.insertionIndex(dropX: metrics.startX + (step * 0.51), metrics: metrics), 1)
        XCTAssertEqual(TileRowLayout.insertionIndex(dropX: metrics.startX + (step * 1.51), metrics: metrics), 2)
        XCTAssertEqual(TileRowLayout.insertionIndex(dropX: metrics.startX + (step * 10), metrics: metrics), 4)
    }

    func testInsertPlacesNewElementAccordingToDropLocation() {
        let baseTileSize = CGSize(width: 60, height: 66)
        let gap: CGFloat = 10
        let availableWidth: CGFloat = 320
        let leftX: CGFloat = 0

        let existing = [1, 2, 3, 4]
        let metrics = TileRowLayout.metrics(
            baseTileSize: baseTileSize,
            baseGap: gap,
            tileCount: existing.count + 1,
            availableWidth: availableWidth,
            leftX: leftX
        )

        let insertedAtStart = TileRowLayout.insert(element: 99, into: existing, dropX: metrics.startX - 50, metrics: metrics)
        XCTAssertEqual(insertedAtStart, [99, 1, 2, 3, 4])

        let step = metrics.tileSize.width + metrics.gap
        let insertedNearEnd = TileRowLayout.insert(element: 99, into: existing, dropX: metrics.startX + (step * 10), metrics: metrics)
        XCTAssertEqual(insertedNearEnd, [1, 2, 3, 4, 99])
    }

    func testScaledGapPreventsRowOverflowWhenShrinkingTiles() {
        let baseTileSize = CGSize(width: 64, height: 70)
        let gap: CGFloat = 10
        let availableWidth: CGFloat = 240
        let leftX: CGFloat = 0

        let metrics = TileRowLayout.metrics(
            baseTileSize: baseTileSize,
            baseGap: gap,
            tileCount: 10,
            availableWidth: availableWidth,
            leftX: leftX
        )

        let totalWidth = (CGFloat(10) * metrics.tileSize.width) + (CGFloat(9) * metrics.gap)
        XCTAssertLessThanOrEqual(totalWidth, availableWidth + 0.001)
    }
}
