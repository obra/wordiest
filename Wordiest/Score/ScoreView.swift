import SwiftUI
import WordiestCore

struct ScoreView: View {
    @ObservedObject var model: AppModel
    var context: AppModel.ScoreContext

    @State private var highlightIndex: Int?
    @State private var isScrubbing = false
    @State private var isCelebrating = false
    @State private var bottomBarHeight: CGFloat = 0
    @State private var scoreGraphFrame: CGRect = .zero

    var body: some View {
        let palette = model.settings.palette
        GeometryReader { rootProxy in
            ZStack {
                VStack(spacing: 16) {
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

                    HStack(alignment: .top) {
                        Text(ScoreSummary.upsetLossesText(count: context.upsetLosses))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(ScoreSummary.expectedLossesText(count: context.expectedLosses))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .foregroundStyle(palette.foreground)
                    .font(.footnote)
                    .padding(.horizontal, 18)

                    scoreGraph()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: ScoreGraphFramePreferenceKey.self, value: proxy.frame(in: .named("ScoreViewSpace")))
                            }
                        )

                    HStack(alignment: .top) {
                        Text(ScoreSummary.expectedWinsText(count: context.expectedWins))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(ScoreSummary.upsetWinsText(count: context.upsetWins))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .foregroundStyle(palette.foreground)
                    .font(.footnote)
                    .padding(.horizontal, 18)

                    Spacer(minLength: 0)

                    WordiestBottomBar(palette: palette) {
                        Button("Play") { model.startNewMatchFromScore() }
                            .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                        Button("History") { model.showHistory() }
                            .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                        Button("Leaders") { model.showLeaders() }
                            .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                        WordiestMenu(
                            model: model,
                            onBack: {
                                model.showMatchReviewFromScore()
                            }
                        )
                        .frame(width: 52)
                        .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                    }
                    .onPreferenceChange(WordiestHeightPreferenceKey.self) { newHeight in
                        if abs(bottomBarHeight - newHeight) > 0.5 {
                            bottomBarHeight = newHeight
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)

                if let idx = highlightIndex, scoreGraphFrame != .zero {
                    let inspectorWidth = min(rootProxy.size.width - 36, 360)
                    let topY = scoreGraphFrame.maxY + 12
                    let bottomY = rootProxy.size.height - bottomBarHeight - 12
                    let availableHeight = max(0, bottomY - topY)
                    let panelHeight = min(availableHeight, 260)
                    if panelHeight >= 80 {
                        ScrollView {
                            OpponentInspectorView(model: model, match: context.match, sampleIndex: idx, maxWidth: inspectorWidth)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .scrollIndicators(.hidden)
                        .frame(width: inspectorWidth, height: panelHeight, alignment: .top)
                        .padding(12)
                        .background(palette.background.opacity(0.98))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(palette.faded.opacity(0.6), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: palette.faded.opacity(0.45), radius: 12, x: 0, y: 8)
                        .offset(x: 18, y: topY)
                        .allowsHitTesting(false)
                        .zIndex(1)
                    }
                }

                if isCelebrating {
                    ConfettiView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

            }
            .coordinateSpace(name: "ScoreViewSpace")
            .onPreferenceChange(ScoreGraphFramePreferenceKey.self) { newFrame in
                if newFrame != .zero {
                    scoreGraphFrame = newFrame
                }
            }
        }
        .tint(palette.foreground)
        .onAppear {
            let should = ScoreSummary.shouldCelebrate(
                opponentsCount: context.match.scoreSamples.count,
                expectedLosses: context.expectedLosses,
                upsetLosses: context.upsetLosses
            )
            if should {
                isCelebrating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isCelebrating = false
                }
            }
        }
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
                            highlightIndex = nil
                        }
                )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct ScoreGraphFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect { .zero }
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
