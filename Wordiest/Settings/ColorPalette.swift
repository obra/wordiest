import SwiftUI

struct ColorPalette: Equatable {
    var background: Color
    var foreground: Color
    var faded: Color

    static func palette(index: Int) -> ColorPalette {
        switch index {
        case 1:
            return .init(background: Color(hex: 0xF3F3F3), foreground: Color(hex: 0x282828), faded: Color(hex: 0xC0C0C0))
        case 2:
            return .init(background: Color(hex: 0x282828), foreground: Color(hex: 0xF3F3F3), faded: Color(hex: 0x5A5A5A))
        case 3:
            return .init(background: Color(hex: 0xEED500), foreground: Color(hex: 0x000000), faded: Color(hex: 0xB29F00))
        case 4:
            return .init(background: Color(hex: 0x513A94), foreground: Color(hex: 0xFFFFFF), faded: Color(hex: 0x6F61C3))
        case 5:
            return .init(background: Color(hex: 0xDF7627), foreground: Color(hex: 0xFFFFFF), faded: Color(hex: 0xF5914D))
        case 6:
            return .init(background: Color(hex: 0x000000), foreground: Color(hex: 0xF3F3F3), faded: Color(hex: 0x5A5A5A))
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

