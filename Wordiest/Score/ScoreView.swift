import SwiftUI
import WordiestCore

struct ScoreView: View {
    @ObservedObject var model: AppModel
    var context: AppModel.ScoreContext

    @State private var highlightIndex: Int?
    @State private var isScrubbing = false
    @State private var isCelebrating = false
    @State private var bottomBarHeight: CGFloat = 0
    @State private var inspectorContentHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let palette = model.settings.palette
        ZStack {
			VStack(spacing: 16) {
				if let tiles = playerTiles(), !tiles.isEmpty {
                    let style: ScoreTileRowView.Style = tiles.count >= 10 ? .compact : .standard
					ScoreTileRowView(palette: palette, tiles: tiles, style: style)
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
            .safeAreaPadding(.top, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(palette.background)

	            if let idx = highlightIndex {
					let opponentScore = context.match.scoreSamples[idx].score
					let anchorToBottom = opponentScore >= context.playerScore
					let inspectorWidth: CGFloat = 360
					let panelWidth = min(UIScreen.main.bounds.width - 36, inspectorWidth)
					let maxPanelHeight: CGFloat = 360

					let content = OpponentInspectorView(model: model, match: context.match, sampleIndex: idx, maxWidth: panelWidth)
						.background(
							GeometryReader { measureProxy in
								Color.clear.preference(key: InspectorHeightPreferenceKey.self, value: measureProxy.size.height)
							}
						)
						.onPreferenceChange(InspectorHeightPreferenceKey.self) { newHeight in
							if abs(inspectorContentHeight - newHeight) > 0.5 {
								inspectorContentHeight = newHeight
							}
						}

					let panel: AnyView = {
						if inspectorContentHeight > 0, inspectorContentHeight > maxPanelHeight {
							return AnyView(
								ScrollView {
									content
								}
								.scrollIndicators(.hidden)
								.frame(height: maxPanelHeight)
							)
						}
						return AnyView(content)
					}()

					let panelView = panel
						.shadow(color: palette.faded.opacity(0.45), radius: 12, x: 0, y: 8)

					VStack(spacing: 0) {
						if !anchorToBottom { panelView }
						Spacer(minLength: 0)
						if anchorToBottom { panelView }
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.padding(.horizontal, 18)
					.padding(.top, anchorToBottom ? 0 : 12)
					.padding(.bottom, anchorToBottom ? (bottomBarHeight + 12) : 0)
					.safeAreaPadding(.top, anchorToBottom ? 0 : 12)
					.safeAreaPadding(.bottom, anchorToBottom ? 12 : 0)
					.allowsHitTesting(false)
		            }

            if isCelebrating {
                ConfettiView()
                    .ignoresSafeArea()
                    .transition(WordiestMotion.overlayTransition(reduceMotion: reduceMotion))
            }

        }
        .tint(palette.foreground)
        .onAppear {
            let should = alwaysCelebrate || ScoreSummary.shouldCelebrate(
                opponentsCount: context.match.scoreSamples.count,
                expectedLosses: context.expectedLosses,
                upsetLosses: context.upsetLosses
            )
            if should {
                withAnimation(WordiestMotion.overlayAnimation(reduceMotion: reduceMotion)) {
                    isCelebrating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(WordiestMotion.overlayAnimation(reduceMotion: reduceMotion)) {
                        isCelebrating = false
                    }
                }
            }
        }
    }

    private var alwaysCelebrate: Bool {
#if DEBUG
        true
#else
        false
#endif
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

private struct InspectorHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
