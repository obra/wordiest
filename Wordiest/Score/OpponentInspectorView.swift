import SwiftUI
import WordiestCore

struct OpponentInspectorView: View {
    @ObservedObject var model: AppModel
    var match: Match
    var sampleIndex: Int

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
                Text([word1, word2].filter { !$0.isEmpty }.joined(separator: "  +  ").uppercased())
                    .foregroundStyle(palette.foreground)
                    .font(.subheadline)

                if let defs = model.assets?.definitions {
                    DefinitionBlock(palette: palette, definitions: defs, word: word1)
                    DefinitionBlock(palette: palette, definitions: defs, word: word2)
                }
            } else {
                Text("No move data.")
                    .foregroundStyle(palette.faded)
                    .font(.subheadline)
            }
        }
        .padding(12)
        .background(palette.background.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(palette.faded.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private struct DefinitionBlock: View {
        var palette: ColorPalette
        var definitions: Definitions
        var word: String

        var body: some View {
            guard !word.isEmpty else { return AnyView(EmptyView()) }
            let def = (try? definitions.definition(for: word)) ?? nil
            if let def {
                return AnyView(
                    Text("\(def.partOfSpeech): \(def.definition)")
                        .foregroundStyle(palette.foreground)
                        .font(.footnote)
                )
            }
            return AnyView(
                Text("Not a word.")
                    .foregroundStyle(palette.faded)
                    .font(.footnote)
            )
        }
    }
}

