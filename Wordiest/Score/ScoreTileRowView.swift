import SwiftUI
import WordiestCore

enum ScoreTile {
    case tile(Tile)
    case plus
}

struct ScoreTileRowView: View {
    struct Style: Equatable {
        var maxTileSize: CGFloat
        var minTileSize: CGFloat
        var spacing: CGFloat

        static let standard = Style(maxTileSize: 44, minTileSize: 26, spacing: 6)
        static let compact = Style(maxTileSize: 40, minTileSize: 18, spacing: 4)
    }

    var palette: ColorPalette
    var tiles: [ScoreTile]
    var style: Style = .standard

    var body: some View {
        GeometryReader { proxy in
            let count = max(tiles.count, 1)
            let totalSpacing = style.spacing * CGFloat(max(0, count - 1))
            let raw = floor((proxy.size.width - totalSpacing) / CGFloat(count))
            let tileSize = min(style.maxTileSize, max(style.minTileSize, raw))

            HStack(spacing: style.spacing) {
                ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                    switch tile {
                    case let .tile(t):
                        WordiestTileView(palette: palette, kind: .tile(t), width: tileSize)
                    case .plus:
                        WordiestTileView(palette: palette, kind: .plus, width: tileSize)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: (style.maxTileSize * WordiestTileStyle.aspectRatio))
    }
}
