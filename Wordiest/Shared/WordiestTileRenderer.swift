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
        let cornerRadius = width * WordiestTileStyle.cornerRadiusRatio
        let borderWidth = max(1, width * WordiestTileStyle.borderWidthRatio)
        let tileOffsetY = height * WordiestTileStyle.tileOffsetYRatio
        let bodyHeight = height - (tileOffsetY * 2)
        let bonusInsetX = width * WordiestTileStyle.bonusInsetXRatio
        let valuePadding = width * WordiestTileStyle.padding6dpRatio

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

            let strokeInset = borderWidth / 2.0
            let strokeCornerRadius = max(0, cornerRadius - strokeInset)
            let bodyRect = CGRect(x: 0, y: tileOffsetY, width: width, height: bodyHeight).insetBy(dx: strokeInset, dy: strokeInset)
            let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: strokeCornerRadius)

            let hasBonus = (tile.bonus?.isEmpty == false)
            let bonusPath: UIBezierPath? = {
                guard hasBonus else { return nil }
                let bonusRect = CGRect(x: bonusInsetX, y: 0, width: width - (bonusInsetX * 2), height: height).insetBy(dx: strokeInset, dy: strokeInset)
                return UIBezierPath(roundedRect: bonusRect, cornerRadius: strokeCornerRadius)
            }()

            cg.setLineWidth(borderWidth)
            cg.setStrokeColor(stroke.cgColor)
            bonusPath?.stroke()
            bodyPath.stroke()

            cg.setFillColor(background.cgColor)
            bonusPath?.fill()
            bodyPath.fill()

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
                let topBaselineY = height * WordiestTileStyle.bonusTopBaselineFromTopRatio
                let bottomBaselineY = height - (height * WordiestTileStyle.bonusBottomBaselineFromBottomRatio)
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
                let valueBaselineY = height - (height * WordiestTileStyle.valueBaselineFromBottomRatio)
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
