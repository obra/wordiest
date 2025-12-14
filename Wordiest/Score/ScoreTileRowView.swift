import SwiftUI
import WordiestCore

enum ScoreTile {
    case tile(Tile)
    case plus
}

struct ScoreTileRowView: View {
    var palette: ColorPalette
    var tiles: [ScoreTile]

    var body: some View {
        GeometryReader { proxy in
            let maxTileSize: CGFloat = 44
            let minTileSize: CGFloat = 26
            let spacing: CGFloat = 6

            let count = max(tiles.count, 1)
            let totalSpacing = spacing * CGFloat(max(0, count - 1))
            let raw = floor((proxy.size.width - totalSpacing) / CGFloat(count))
            let tileSize = min(maxTileSize, max(minTileSize, raw))

            HStack(spacing: spacing) {
                ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                    ScoreTileView(palette: palette, tile: tile, size: tileSize)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 44 * 1.10)
    }

    private struct ScoreTileView: View {
        var palette: ColorPalette
        var tile: ScoreTile
        var size: CGFloat

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(palette.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(palette.foreground, lineWidth: 2)
                    )

                content()
                    .padding(.horizontal, 5)
            }
            .frame(width: size, height: size * 1.10)
        }

        @ViewBuilder
        private func content() -> some View {
            switch tile {
            case let .tile(t):
                ZStack {
                    Text(t.letter.uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(palette.foreground)

                    VStack {
                        if let bonus = t.bonus, !bonus.isEmpty {
                            Text(bonus.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(palette.foreground)
                        } else {
                            Color.clear.frame(height: 10)
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            Text(t.value > 0 ? String(t.value) : "")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(palette.foreground)
                        }
                    }
                }
            case .plus:
                Text("+")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(palette.foreground)
            }
        }
    }
}
