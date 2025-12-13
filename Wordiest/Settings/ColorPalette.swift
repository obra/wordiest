import SwiftUI
import UIKit

struct ColorPalette: Equatable {
    private var backgroundHex: UInt32
    private var foregroundHex: UInt32
    private var fadedHex: UInt32

    var background: Color { Color(hex: backgroundHex) }
    var foreground: Color { Color(hex: foregroundHex) }
    var faded: Color { Color(hex: fadedHex) }

    var uiBackground: UIColor { UIColor(hex: backgroundHex) }
    var uiForeground: UIColor { UIColor(hex: foregroundHex) }
    var uiFaded: UIColor { UIColor(hex: fadedHex) }

    static func palette(index: Int) -> ColorPalette {
        switch index {
        case 1:
            return .init(backgroundHex: 0xF3F3F3, foregroundHex: 0x282828, fadedHex: 0xC0C0C0)
        case 2:
            return .init(backgroundHex: 0x282828, foregroundHex: 0xF3F3F3, fadedHex: 0x5A5A5A)
        case 3:
            return .init(backgroundHex: 0xEED500, foregroundHex: 0x000000, fadedHex: 0xB29F00)
        case 4:
            return .init(backgroundHex: 0x513A94, foregroundHex: 0xFFFFFF, fadedHex: 0x6F61C3)
        case 5:
            return .init(backgroundHex: 0xDF7627, foregroundHex: 0xFFFFFF, fadedHex: 0xF5914D)
        case 6:
            return .init(backgroundHex: 0x000000, foregroundHex: 0xF3F3F3, fadedHex: 0x5A5A5A)
        default:
            return palette(index: 1)
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
