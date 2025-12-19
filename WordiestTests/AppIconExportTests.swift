import UIKit
import WordiestCore
import XCTest
@testable import Wordiest

final class AppIconExportTests: XCTestCase {
    @MainActor
    func testExportAppIconOptionC() throws {
        #if WORDIEST_ICON_EXPORT
        let icon = renderOptionC()
        let attachment = XCTAttachment(image: icon)
        attachment.name = "C-blue-badge.png"
        attachment.lifetime = .keepAlways
        add(attachment)
        #else
        throw XCTSkip("Define WORDIEST_ICON_EXPORT to enable icon export.")
        #endif
    }
}

@MainActor
private func renderOptionC() -> UIImage {
    let iconSize = CGSize(width: 1024, height: 1024)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true

    let renderer = UIGraphicsImageRenderer(size: iconSize, format: format)
    return renderer.image { ctx in
        let cg = ctx.cgContext

        // Background: deep blue radial gradient.
        let bgCenter = CGPoint(x: iconSize.width * 0.50, y: iconSize.height * 0.40)
        drawRadialGradient(
            in: cg,
            center: bgCenter,
            innerRadius: 0,
            outerRadius: iconSize.width * 0.75,
            innerColor: UIColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1.0), // #3B82F6
            outerColor: UIColor(red: 0.043, green: 0.102, blue: 0.227, alpha: 1.0)  // #0B1A3A
        )

        let drawWidth: CGFloat = 700
        let drawHeight = drawWidth * WordiestTileStyle.aspectRatio

        // Tile: rendered at the same *relative sizes* as the in-app tiles (same renderer),
        // but at the final drawn size to avoid resampling artifacts.
        let tile = Tile(letter: "W", value: 4, bonus: "4W")
        let tileImage = WordiestTileRenderer.image(
            tile: tile,
            size: CGSize(width: drawWidth, height: drawHeight),
            background: .white,
            foreground: .black,
            stroke: UIColor(white: 0.15, alpha: 1.0),
            scale: 1
        )

        let tileCenter = CGPoint(x: iconSize.width * 0.52, y: iconSize.height * 0.51)
        cg.saveGState()
        cg.translateBy(x: tileCenter.x, y: tileCenter.y)
        cg.rotate(by: 8.0 * (.pi / 180.0))

        // Keep the tile "flat" (App Store icons shouldn't look like a floating card).

        let drawRect = CGRect(x: -drawWidth / 2.0, y: -drawHeight / 2.0, width: drawWidth, height: drawHeight)
        tileImage.draw(in: drawRect)
        cg.restoreGState()
    }
}

private func drawRadialGradient(in cg: CGContext, center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat, innerColor: UIColor, outerColor: UIColor) {
    guard let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [innerColor.cgColor, outerColor.cgColor] as CFArray,
        locations: [0.0, 1.0]
    ) else {
        return
    }

    cg.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: innerRadius,
        endCenter: center,
        endRadius: outerRadius,
        options: [.drawsAfterEndLocation]
    )
}
