import SwiftUI
import WordiestCore

struct OpponentInspectorView: View {
    @ObservedObject var model: AppModel
    var match: Match
    var sampleIndex: Int
    var maxWidth: CGFloat = 360

    var body: some View {
        let palette = model.settings.palette
        VStack(alignment: .leading, spacing: 8) {
            let sample = match.scoreSamples[sampleIndex]

            Text(MatchStrings.totalScore(sample.score))
                .foregroundStyle(palette.foreground)
                .font(.headline)

            if let wordsEncoding = sample.wordsEncoding,
               let decoded = try? SubsetEncoding.decode(wordsEncoding, tileCount: match.tiles.count) {
                let word1 = decoded.word1.map { match.tiles[$0].letter }.joined()
                let word2 = decoded.word2.map { match.tiles[$0].letter }.joined()
                let word1Tiles = decoded.word1.map { match.tiles[$0] }
                let word2Tiles = decoded.word2.map { match.tiles[$0] }

                let rowTiles = tilesForRow(word1Tiles: word1Tiles, word2Tiles: word2Tiles)
                if !rowTiles.isEmpty {
                    ScoreTileRowView(palette: palette, tiles: rowTiles, style: .compact)
                }

                if let defs = model.assets?.definitions {
                    DefinitionBlock(palette: palette, definitions: defs, word: word1, tiles: word1Tiles)
                    DefinitionBlock(palette: palette, definitions: defs, word: word2, tiles: word2Tiles)
                }
            } else {
                Text("No move data.")
                    .foregroundStyle(palette.faded)
                    .font(.subheadline)
            }
        }
        .padding(12)
        .background(palette.background)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(palette.faded.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: maxWidth, alignment: .leading)
    }

    private struct DefinitionBlock: View {
        var palette: ColorPalette
        var definitions: Definitions
        var word: String
        var tiles: [Tile]

        var body: some View {
            guard !word.isEmpty else { return AnyView(EmptyView()) }
            let def = (try? definitions.definition(for: word)) ?? nil
            guard let def else { return AnyView(EmptyView()) }

            let points = (try? WordiestScoring.scoreWord(tiles)) ?? 0
            return AnyView(
                formattedDefinition(definition: def, points: points)
                    .foregroundStyle(palette.foreground)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            )
        }

        private func formattedDefinition(definition: Definitions.Definition, points: Int) -> Text {
            let plural = points == 1 ? "" : "s"
            var text = Text(definition.word.uppercased()).bold()
            if points > 0 {
                text = text + Text(" (\(points) pt\(plural))")
            }
            if let see = definition.seeWord {
                text = text + Text(", see ") + Text(see.uppercased()).bold()
            }
            return text + Text(": \(definition.definition)")
        }
    }

    private func tilesForRow(word1Tiles: [Tile], word2Tiles: [Tile]) -> [ScoreTile] {
        var tiles: [ScoreTile] = []
        tiles.reserveCapacity(word1Tiles.count + word2Tiles.count + 1)
        for t in word1Tiles { tiles.append(.tile(t)) }
        if !word1Tiles.isEmpty, !word2Tiles.isEmpty { tiles.append(.plus) }
        for t in word2Tiles { tiles.append(.tile(t)) }
        return tiles
    }
}
