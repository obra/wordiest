import SwiftUI
import UIKit
import WordiestCore

struct WordiestTileView: View {
    enum Kind: Equatable {
        case tile(Tile)
        case plus
    }

    var palette: ColorPalette
    var kind: Kind
    var width: CGFloat

    var body: some View {
        let height = width * WordiestTileStyle.aspectRatio
        let scale = UIScreen.main.scale

        ZStack {
            switch kind {
            case let .tile(t):
                let image = WordiestTileRenderer.image(
                    kind: .tile(t),
                    width: width,
                    palette: palette,
                    strokeColor: palette.uiForeground,
                    scale: scale
                )
                Image(uiImage: image)
                    .interpolation(.none)
            case .plus:
                let image = WordiestTileRenderer.image(
                    kind: .plus,
                    width: width,
                    palette: palette,
                    strokeColor: palette.uiForeground,
                    scale: scale
                )
                Image(uiImage: image)
                    .interpolation(.none)
            }
        }
        .frame(width: width, height: height)
    }
}
