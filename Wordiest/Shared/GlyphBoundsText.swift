import CoreText
import UIKit

enum GlyphBoundsText {
    private struct CacheKey: Hashable {
        var text: String
        var fontName: String
        var fontSizeX100: Int
        var scaleX100: Int
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
        c.countLimit = 256
        return c
    }()

    static func image(text: String, font: UIFont, scale: CGFloat) -> UIImage {
        let key = CacheKey(
            text: text,
            fontName: font.fontName,
            fontSizeX100: Int((font.pointSize * 100).rounded()),
            scaleX100: Int((scale * 100).rounded())
        )
        let wrapped = WrappedKey(key)
        if let cached = cache.object(forKey: wrapped) {
            return cached
        }

        let image = render(text: text, font: font, scale: scale)
        cache.setObject(image, forKey: wrapped)
        return image
    }

    private static func render(text: String, font: UIFont, scale: CGFloat) -> UIImage {
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

        if bounds.isNull || bounds.size.width <= 0 || bounds.size.height <= 0 {
            return UIImage()
        }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale

        let size = bounds.size
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.translateBy(x: 0, y: size.height)
            cg.scaleBy(x: 1, y: -1)
            cg.translateBy(x: -bounds.minX, y: -bounds.minY)
            cg.textPosition = .zero
            CTLineDraw(line, cg)
        }
    }
}
