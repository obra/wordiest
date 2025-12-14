import SwiftUI

struct WordiestButtonBar<Content: View>: View {
    var palette: ColorPalette
    private var content: (_ wideWidth: CGFloat, _ menuWidth: CGFloat) -> Content

    init(palette: ColorPalette, @ViewBuilder content: @escaping (_ wideWidth: CGFloat, _ menuWidth: CGFloat) -> Content) {
        self.palette = palette
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 1
            let availableWidth = proxy.size.width
            let unit = max(0, (availableWidth - (spacing * 3)) / 10.0)
            let wideWidth = unit * 3.0
            let menuWidth = unit * 1.0

            HStack(spacing: spacing) {
                content(wideWidth, menuWidth)
            }
            .padding(.top, 1)
        }
        .frame(height: 50)
        .background(palette.faded)
    }
}
