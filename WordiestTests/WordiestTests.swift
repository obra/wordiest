import SpriteKit
import SwiftUI
import UIKit
import WordiestCore
import XCTest
@testable import Wordiest

final class WordiestTests: XCTestCase {
    @MainActor
    func testBonusTabDoesNotShowBodyBorderLine() {
        let palette = ColorPalette.palette(index: 1)
        let tile = Tile(letter: "p", value: 3, bonus: "2L")
        guard let image = renderToImage(
            WordiestTileView(palette: palette, kind: .tile(tile), width: 64),
            size: CGSize(width: 64, height: WordiestTileStyle.height(forWidth: 64))
        ) else {
            XCTFail("Unable to render WordiestTileView")
            return
        }

        // The Android TileView draws the body border and then redraws the bonus tab fill above it to erase
        // the border line segment that would otherwise cut across the tab/body overlap.
        //
        // Sample a pixel inside the overlap region (away from the centered bonus text) near the body's top edge.
        let sample = image.pixelColor(at: CGPoint(x: 18, y: 9))
        XCTAssertTrue(sample.isClose(to: palette.uiBackground, tolerance: 0.12), "Expected overlap region to be background, got \(sample)")
    }

    @MainActor
    func testDraggedTileCoversDefinitionArea() {
        let scene = SKScene(size: CGSize(width: 200, height: 200))
        scene.backgroundColor = .black

        let behind = SKShapeNode(rectOf: CGSize(width: 120, height: 60))
        behind.fillColor = .red
        behind.strokeColor = .clear
        behind.position = CGPoint(x: 100, y: 100)
        behind.zPosition = 20
        scene.addChild(behind)

        let tile = TileNode(tile: Tile(letter: "a", value: 1, bonus: "2L"), size: CGSize(width: 64, height: 80), fontName: "IstokWeb-Bold")
        tile.applyPalette(background: .black, foreground: .white, faded: .gray)
        tile.position = CGPoint(x: 100, y: 100)
        tile.zPosition = 30
        scene.addChild(tile)

        let point = CGPoint(x: 100, y: 100)
        let nodes = scene.nodes(at: point)
        XCTAssertFalse(nodes.isEmpty)
        let topNode = nodes[0]
        let topTile = (topNode as? TileNode) ?? (topNode.parent as? TileNode)
        XCTAssertNotNil(topTile, "Expected dragged tile to be topmost at \(point), got \(topNode)")
    }
}

@MainActor
private func renderToImage<V: View>(_ view: V, size: CGSize) -> UIImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(size)
    return renderer.uiImage
}

private extension UIColor {
    func isClose(to other: UIColor, tolerance: CGFloat) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) <= tolerance && abs(g1 - g2) <= tolerance && abs(b1 - b2) <= tolerance && abs(a1 - a2) <= tolerance
    }
}

private extension UIImage {
    func pixelColor(at point: CGPoint) -> UIColor {
        guard let cg = cgImage else { return .clear }
        let scale = scale
        let x = Int(point.x * scale)
        let y = Int(point.y * scale)
        guard x >= 0, y >= 0, x < cg.width, y < cg.height else { return .clear }
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else { return .clear }

        var pixel: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: info) else {
            return .clear
        }
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        return UIColor(
            red: CGFloat(pixel[0]) / 255.0,
            green: CGFloat(pixel[1]) / 255.0,
            blue: CGFloat(pixel[2]) / 255.0,
            alpha: CGFloat(pixel[3]) / 255.0
        )
    }
}
