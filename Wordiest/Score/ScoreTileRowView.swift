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
        HStack(spacing: 8) {
            ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                ScoreTileView(palette: palette, tile: tile)
            }
        }
    }

    private struct ScoreTileView: View {
        var palette: ColorPalette
        var tile: ScoreTile

        var body: some View {
            let size: CGFloat = 44
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

