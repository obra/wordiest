import SwiftUI
import WordiestCore

struct ScoreView: View {
    @ObservedObject var model: AppModel
    var context: AppModel.ScoreContext

    @State private var highlightIndex: Int?
    @State private var isScrubbing = false

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 16) {
            HStack {
                Button("Back") { model.showMatchReviewFromScore() }
                    .buttonStyle(.bordered)
                Spacer()
                MenuButton(model: model)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            if let tiles = playerTiles(), !tiles.isEmpty {
                ScoreTileRowView(palette: palette, tiles: tiles)
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
            }

            Text(ScoreSummary.scoreText(score: context.playerScore, percentile: context.percentile))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
                .padding(.horizontal, 18)

            Text(ScoreSummary.ratingText(old: context.oldRating, new: context.newRating, matchCount: context.matchCountBefore))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
                .padding(.horizontal, 18)

            VStack(spacing: 6) {
                HStack {
                    Text(ScoreSummary.upsetLossesText(count: context.upsetLosses))
                        .foregroundStyle(palette.foreground)
                        .font(.footnote)
                    Spacer()
                    Text(ScoreSummary.expectedLossesText(count: context.expectedLosses))
                        .foregroundStyle(palette.foreground)
                        .font(.footnote)
                }

                HStack {
                    Text(ScoreSummary.expectedWinsText(count: context.expectedWins))
                        .foregroundStyle(palette.foreground)
                        .font(.footnote)
                    Spacer()
                    Text(ScoreSummary.upsetWinsText(count: context.upsetWins))
                        .foregroundStyle(palette.foreground)
                        .font(.footnote)
                }
            }
            .padding(.horizontal, 18)

            scoreGraph()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)

            if let idx = highlightIndex {
                OpponentInspectorView(model: model, match: context.match, sampleIndex: idx)
                    .padding(.horizontal, 18)
            }

            HStack(spacing: 12) {
                Button("Play") { model.startNewMatchFromScore() }
                Button("History") { model.showHistory() }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }

    private func playerTiles() -> [ScoreTile]? {
        guard let decoded = try? SubsetEncoding.decode(context.playerEncoding, tileCount: context.match.tiles.count) else { return nil }
        let word1 = decoded.word1.map { context.match.tiles[$0] }
        let word2 = decoded.word2.map { context.match.tiles[$0] }

        var tiles: [ScoreTile] = []
        tiles.reserveCapacity(word1.count + word2.count + 1)
        for t in word1 { tiles.append(.tile(t)) }
        if !word1.isEmpty, !word2.isEmpty { tiles.append(.plus) }
        for t in word2 { tiles.append(.tile(t)) }
        return tiles
    }

    @ViewBuilder
    private func scoreGraph() -> some View {
        let palette = model.settings.palette
        let points: [CGPoint] = context.match.scoreSamples.map { CGPoint(x: Double($0.ratingX10) / 10.0, y: Double($0.score)) }
        let center = CGPoint(x: context.newRating, y: Double(context.playerScore))

        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size).insetBy(dx: 12, dy: 12)
            let mapping = ScoreGraphMath.mappedPoints(points: points, center: center, rect: rect)

            ScoreGraphView(palette: palette, points: points, center: center, highlightIndex: highlightIndex)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let location = value.location
                            highlightIndex = ScoreGraphMath.nearestPointIndex(inScreenSpace: location, mappedPoints: mapping.mapped)
                        }
                        .onEnded { _ in
                            isScrubbing = false
                        }
                )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
