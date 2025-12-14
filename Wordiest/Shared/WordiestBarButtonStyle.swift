import SwiftUI

struct WordiestBarButtonStyle: ButtonStyle {
    var palette: ColorPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18))
            .foregroundStyle(palette.foreground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .background(Color(uiColor: WordiestButtonColors.backgroundUIColor(palette: palette, isPressed: configuration.isPressed)))
    }
}

