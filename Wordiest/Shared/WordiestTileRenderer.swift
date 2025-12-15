import CoreText
import UIKit
import WordiestCore

enum WordiestTileRenderer {
    enum Kind: Hashable {
        case tile(Tile)
        case plus
    }

    private struct CacheKey: Hashable {
        var kind: Int
        var letter: String
        var value: Int
        var bonus: String
        var widthX100: Int
        var heightX100: Int
        var scaleX100: Int
        var backgroundRGBA: UInt32
        var foregroundRGBA: UInt32
        var strokeRGBA: UInt32
    }

    private final class WrappedKey: NSObject {
        let key: CacheKey
        init(_ key: CacheKey) { self.key = key }
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? WrappedKey else { return false }
            return key == other.key
        }
        override var hash: Int { key.hashValue }
    }

    private nonisolated(unsafe) static let cache: NSCache<WrappedKey, UIImage> = {
        let c = NSCache<WrappedKey, UIImage>()
        c.countLimit = 512
        return c
    }()

    static func image(kind: Kind, width: CGFloat, palette: ColorPalette, strokeColor: UIColor, scale: CGFloat) -> UIImage {
        let (keyKind, letter, value, bonus) = tileKeyParts(kind: kind)

        let key = CacheKey(
            kind: keyKind,
            letter: letter,
            value: value,
            bonus: bonus,
            widthX100: Int((width * 100).rounded()),
            heightX100: Int(((width * WordiestTileStyle.aspectRatio) * 100).rounded()),
            scaleX100: Int((scale * 100).rounded()),
            backgroundRGBA: rgba(palette.uiBackground),
            foregroundRGBA: rgba(palette.uiForeground),
            strokeRGBA: rgba(strokeColor)
        )

        let wrapped = WrappedKey(key)
        if let cached = cache.object(forKey: wrapped) {
            return cached
        }

        let image = render(kind: kind, width: width, palette: palette, strokeColor: strokeColor, scale: scale)
        cache.setObject(image, forKey: wrapped)
        return image
    }

    static func image(tile: Tile, size: CGSize, background: UIColor, foreground: UIColor, stroke: UIColor, scale: CGFloat) -> UIImage {
        let key = CacheKey(
            kind: 0,
            letter: tile.letter.uppercased(),
            value: tile.value,
            bonus: (tile.bonus ?? "").uppercased(),
            widthX100: Int((size.width * 100).rounded()),
            heightX100: Int((size.height * 100).rounded()),
            scaleX100: Int((scale * 100).rounded()),
            backgroundRGBA: rgba(background),
            foregroundRGBA: rgba(foreground),
            strokeRGBA: rgba(stroke)
        )

        let wrapped = WrappedKey(key)
        if let cached = cache.object(forKey: wrapped) {
            return cached
        }

        let image = renderTile(tile: tile, width: size.width, height: size.height, background: background, foreground: foreground, stroke: stroke, scale: scale)
        cache.setObject(image, forKey: wrapped)
        return image
    }

    private static func tileKeyParts(kind: Kind) -> (Int, String, Int, String) {
        switch kind {
        case let .tile(t):
            return (0, t.letter.uppercased(), t.value, (t.bonus ?? "").uppercased())
        case .plus:
            return (1, "+", 0, "")
        }
    }

    private static func rgba(_ color: UIColor) -> UInt32 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt32((r * 255).rounded())
        let gi = UInt32((g * 255).rounded())
        let bi = UInt32((b * 255).rounded())
        let ai = UInt32((a * 255).rounded())
        return (ri << 24) | (gi << 16) | (bi << 8) | ai
    }

    private static func render(kind: Kind, width: CGFloat, palette: ColorPalette, strokeColor: UIColor, scale: CGFloat) -> UIImage {
        let height = width * WordiestTileStyle.aspectRatio
        switch kind {
        case let .tile(t):
            return renderTile(
                tile: t,
                width: width,
                height: height,
                background: palette.uiBackground,
                foreground: palette.uiForeground,
                stroke: strokeColor,
                scale: scale
            )
        case .plus:
            return renderPlus(width: width, height: height, foreground: palette.uiForeground, scale: scale)
        }
    }

    private static func renderTile(tile: Tile, width: CGFloat, height: CGFloat, background: UIColor, foreground: UIColor, stroke: UIColor, scale: CGFloat) -> UIImage {
        let pixel = 1.0 / scale
        func snapDown(_ value: CGFloat) -> CGFloat { floor(value / pixel) * pixel }
        func snapUp(_ value: CGFloat) -> CGFloat { ceil(value / pixel) * pixel }
        func snapRect(_ rect: CGRect) -> CGRect {
            let x1 = snapDown(rect.minX)
            let y1 = snapDown(rect.minY)
            let x2 = snapUp(rect.maxX)
            let y2 = snapUp(rect.maxY)
            return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
        }

        let cornerRadius = snapDown(width * WordiestTileStyle.cornerRadiusRatio)
        let borderWidthPxUnrounded = (width * WordiestTileStyle.borderWidthRatio) * scale
        var borderWidthPx = max(1, Int(borderWidthPxUnrounded.rounded()))
        if borderWidthPx % 2 != 0 { borderWidthPx += 1 } // keep strokeInset pixel-aligned
        let borderWidth = CGFloat(borderWidthPx) / scale

        let tileOffsetY = cornerRadius
        let bodyHeight = height - (tileOffsetY * 2)
        let bonusInsetX = snapDown(width * WordiestTileStyle.bonusInsetXRatio)
        let valuePadding = snapDown(width * WordiestTileStyle.padding6dpRatio)

        let letterFontSize = width * WordiestTileStyle.letterFontRatio
        let smallFontSize = width * WordiestTileStyle.smallFontRatio
        let letterFont = UIFont(name: "IstokWeb-Bold", size: letterFontSize) ?? .systemFont(ofSize: letterFontSize, weight: .bold)
        let smallFont = UIFont(name: "IstokWeb-Bold", size: smallFontSize) ?? .systemFont(ofSize: smallFontSize, weight: .bold)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setAllowsAntialiasing(true)
            cg.setShouldAntialias(true)

            let bodyFillRect = snapRect(CGRect(x: 0, y: tileOffsetY, width: width, height: bodyHeight))
            let bodyFillPath = UIBezierPath(roundedRect: bodyFillRect, cornerRadius: cornerRadius)

            let hasBonus = (tile.bonus?.isEmpty == false)
            let bonusFillRect: CGRect? = {
                guard hasBonus else { return nil }
                return snapRect(CGRect(x: bonusInsetX, y: 0, width: width - (bonusInsetX * 2), height: height))
            }()
            let bonusFillPath: UIBezierPath? = bonusFillRect.map { bonusTileFillPath(bodyRect: bodyFillRect, bonusRect: $0, cornerRadius: cornerRadius) }

            let tileFillPath: UIBezierPath = bonusFillPath ?? bodyFillPath

            cg.setFillColor(background.cgColor)
            tileFillPath.fill()

            // Stroke only inside the filled tile shape to avoid clipped top/bottom edges (bonus tiles)
            // and to avoid "double-stroke" artifacts from layering multiple overlapping strokes.
            cg.saveGState()
            cg.addPath(tileFillPath.cgPath)
            cg.clip()
            cg.setLineWidth(borderWidth * 2.0)
            cg.setLineJoin(.round)
            cg.setLineCap(.round)
            cg.setStrokeColor(stroke.cgColor)
            cg.addPath(tileFillPath.cgPath)
            cg.strokePath()
            cg.restoreGState()

            drawGlyphText(
                text: tile.letter.uppercased(),
                font: letterFont,
                color: foreground,
                center: CGPoint(x: width / 2.0, y: height / 2.0),
                canvasHeight: height,
                in: cg
            )

            if let bonus = tile.bonus, !bonus.isEmpty {
                let bonusText = bonus.uppercased()
                let bonusBounds = glyphBounds(text: bonusText, font: smallFont)
                let verticalInset = bonusBounds.height * 0.10

                let topBaselineY = snapDown((height * WordiestTileStyle.bonusTopBaselineFromTopRatio) + verticalInset)
                let bottomBaselineY = snapDown(height - (height * WordiestTileStyle.bonusBottomBaselineFromBottomRatio) - verticalInset)
                drawGlyphTextAtBaseline(
                    text: bonusText,
                    font: smallFont,
                    color: foreground,
                    baseline: CGPoint(x: width / 2.0, y: topBaselineY),
                    horizontalAlignment: .center,
                    canvasHeight: height,
                    in: cg
                )
                drawGlyphTextAtBaseline(
                    text: bonusText,
                    font: smallFont,
                    color: foreground,
                    baseline: CGPoint(x: width / 2.0, y: bottomBaselineY),
                    horizontalAlignment: .center,
                    canvasHeight: height,
                    in: cg
                )
            }

            if tile.value > 0 {
                let valueText = String(tile.value)
                let valueBaselineY = snapDown(height - (height * WordiestTileStyle.valueBaselineFromBottomRatio))
                drawGlyphTextAtBaseline(
                    text: valueText,
                    font: smallFont,
                    color: foreground,
                    baseline: CGPoint(x: width - valuePadding, y: valueBaselineY),
                    horizontalAlignment: .right,
                    canvasHeight: height,
                    in: cg
                )
            }
        }
    }

    private static func bonusTileFillPath(bodyRect: CGRect, bonusRect: CGRect, cornerRadius: CGFloat) -> UIBezierPath {
        let r = max(0, cornerRadius)

        let bodyMinX = bodyRect.minX
        let bodyMaxX = bodyRect.maxX
        let bodyMinY = bodyRect.minY
        let bodyMaxY = bodyRect.maxY

        let bonusMinX = bonusRect.minX
        let bonusMaxX = bonusRect.maxX
        let bonusMinY = bonusRect.minY
        let bonusMaxY = bonusRect.maxY

        let path = UIBezierPath()

        // Union outline between the body (wider) and the bonus tab (narrower) has *sharp* corners
        // at the body/tab transition points (bonusMinX/bodyMinY etc.). Those must not be rounded,
        // otherwise the outline self-intersects and the stroke becomes discontinuous.

        // Start: body top edge, after top-left corner.
        path.move(to: CGPoint(x: bodyMinX + r, y: bodyMinY))
        path.addLine(to: CGPoint(x: bonusMinX, y: bodyMinY))

        // Up bonus tab left edge to top-left corner.
        path.addLine(to: CGPoint(x: bonusMinX, y: bonusMinY + r))
        path.addArc(
            withCenter: CGPoint(x: bonusMinX + r, y: bonusMinY + r),
            radius: r,
            startAngle: .pi,
            endAngle: 3.0 * .pi / 2.0,
            clockwise: true
        )

        // Across bonus tab top to top-right corner.
        path.addLine(to: CGPoint(x: bonusMaxX - r, y: bonusMinY))
        path.addArc(
            withCenter: CGPoint(x: bonusMaxX - r, y: bonusMinY + r),
            radius: r,
            startAngle: 3.0 * .pi / 2.0,
            endAngle: 0,
            clockwise: true
        )

        // Down bonus tab right edge to body top edge.
        path.addLine(to: CGPoint(x: bonusMaxX, y: bodyMinY))
        path.addLine(to: CGPoint(x: bodyMaxX - r, y: bodyMinY))

        // Body top-right corner.
        path.addArc(
            withCenter: CGPoint(x: bodyMaxX - r, y: bodyMinY + r),
            radius: r,
            startAngle: 3.0 * .pi / 2.0,
            endAngle: 0,
            clockwise: true
        )

        // Down body right edge to body bottom-right.
        path.addLine(to: CGPoint(x: bodyMaxX, y: bodyMaxY - r))
        path.addArc(
            withCenter: CGPoint(x: bodyMaxX - r, y: bodyMaxY - r),
            radius: r,
            startAngle: 0,
            endAngle: .pi / 2.0,
            clockwise: true
        )

        // Across body bottom to bonus tab right edge, then down to bonus bottom-right.
        path.addLine(to: CGPoint(x: bonusMaxX, y: bodyMaxY))
        path.addLine(to: CGPoint(x: bonusMaxX, y: bonusMaxY - r))
        path.addArc(
            withCenter: CGPoint(x: bonusMaxX - r, y: bonusMaxY - r),
            radius: r,
            startAngle: 0,
            endAngle: .pi / 2.0,
            clockwise: true
        )

        // Across bonus bottom to bottom-left corner.
        path.addLine(to: CGPoint(x: bonusMinX + r, y: bonusMaxY))
        path.addArc(
            withCenter: CGPoint(x: bonusMinX + r, y: bonusMaxY - r),
            radius: r,
            startAngle: .pi / 2.0,
            endAngle: .pi,
            clockwise: true
        )

        // Up bonus tab left edge to body bottom, then across to body bottom-left.
        path.addLine(to: CGPoint(x: bonusMinX, y: bodyMaxY))
        path.addLine(to: CGPoint(x: bodyMinX + r, y: bodyMaxY))

        // Body bottom-left corner.
        path.addArc(
            withCenter: CGPoint(x: bodyMinX + r, y: bodyMaxY - r),
            radius: r,
            startAngle: .pi / 2.0,
            endAngle: .pi,
            clockwise: true
        )

        // Up body left edge to body top-left corner, then close.
        path.addLine(to: CGPoint(x: bodyMinX, y: bodyMinY + r))
        path.addArc(
            withCenter: CGPoint(x: bodyMinX + r, y: bodyMinY + r),
            radius: r,
            startAngle: .pi,
            endAngle: 3.0 * .pi / 2.0,
            clockwise: true
        )
        path.close()
        return path
    }

    private static func renderPlus(width: CGFloat, height: CGFloat, foreground: UIColor, scale: CGFloat) -> UIImage {
        let fontSize = width * WordiestTileStyle.letterFontRatio
        let font = UIFont(name: "IstokWeb-Bold", size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .bold)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            drawGlyphText(
                text: "+",
                font: font,
                color: foreground,
                center: CGPoint(x: width / 2.0, y: height / 2.0),
                canvasHeight: height,
                in: cg
            )
        }
    }

    private static func glyphBounds(text: String, font: UIFont) -> CGRect {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        var bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        bounds.origin.x = floor(bounds.origin.x)
        bounds.origin.y = floor(bounds.origin.y)
        bounds.size.width = ceil(bounds.size.width)
        bounds.size.height = ceil(bounds.size.height)
        return bounds
    }

    private enum HorizontalAlignment {
        case center
        case right
    }

    private static func drawGlyphTextAtBaseline(text: String, font: UIFont, color: UIColor, baseline: CGPoint, horizontalAlignment: HorizontalAlignment, canvasHeight: CGFloat, in cg: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])

        let originX: CGFloat = {
            switch horizontalAlignment {
            case .center:
                return baseline.x - bounds.midX
            case .right:
                return baseline.x - bounds.maxX
            }
        }()

        cg.saveGState()
        cg.textMatrix = .identity
        cg.translateBy(x: 0, y: canvasHeight)
        cg.scaleBy(x: 1, y: -1)

        let baselineYUp = canvasHeight - baseline.y
        cg.textPosition = CGPoint(x: originX, y: baselineYUp)
        CTLineDraw(line, cg)
        cg.restoreGState()
    }

    private static func drawGlyphText(text: String, font: UIFont, color: UIColor, center: CGPoint, canvasHeight: CGFloat, in cg: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])

        cg.saveGState()
        cg.textMatrix = .identity
        cg.translateBy(x: 0, y: canvasHeight)
        cg.scaleBy(x: 1, y: -1)

        let centerYUp = canvasHeight - center.y
        let origin = CGPoint(
            x: center.x - bounds.midX,
            y: centerYUp - bounds.midY
        )
        cg.textPosition = origin
        CTLineDraw(line, cg)
        cg.restoreGState()
    }
}
