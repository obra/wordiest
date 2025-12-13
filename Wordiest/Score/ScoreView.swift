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

            Text(ScoreSummary.scoreText(score: context.playerScore, percentile: context.percentile))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
                .padding(.horizontal, 18)

            Text(ScoreSummary.ratingText(old: context.oldRating, new: context.newRating, matchCount: context.matchCountBefore))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
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
