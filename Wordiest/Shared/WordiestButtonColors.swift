import UIKit

enum WordiestButtonColors {
    static func backgroundUIColor(palette: ColorPalette, isPressed: Bool) -> UIColor {
        isPressed ? palette.uiFaded : palette.uiBackground
    }
}

