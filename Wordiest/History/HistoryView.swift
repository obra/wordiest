import SwiftUI
import WordiestCore

struct HistoryView: View {
    @ObservedObject var model: AppModel
    @State private var pendingDelete: HistoryEntry?
    @State private var visibleRowFrames: [Int: CGRect] = [:]
    @State private var highlightStart: Int?
    @State private var highlightEnd: Int?

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 0) {
            if model.historyStore.entries.isEmpty {
                VStack {
                    Spacer()
                    Text("History is empty, play some games!")
                        .foregroundStyle(palette.foreground)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
            } else {
                VStack(spacing: 12) {
                    sparklineHeader(palette: palette)
                        .padding(.horizontal, 18)

                    ScrollViewReader { reader in
                        GeometryReader { viewportProxy in
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(Array(model.historyStore.entries.enumerated()), id: \.element.id) { index, entry in
                                        HistoryRowView(palette: palette, entry: entry)
                                            .id(entry.id)
                                            .background(
                                                GeometryReader { rowProxy in
                                                    Color.clear.preference(
                                                        key: HistoryRowFramePreferenceKey.self,
                                                        value: [index: rowProxy.frame(in: .global)]
                                                    )
                                                }
                                            )
                                            .onTapGesture {
                                                openReview(entry: entry)
                                            }
                                            .onLongPressGesture {
                                                pendingDelete = entry
                                            }
                                        Divider().background(palette.faded.opacity(0.6))
                                    }
                                }
                            }
                            .onPreferenceChange(HistoryRowFramePreferenceKey.self) { frames in
                                visibleRowFrames = frames
                                updateHighlight(viewport: viewportProxy.frame(in: .global))
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0).onChanged { value in
                                    if value.location.y < 90 {
                                        scrub(toX: value.location.x, width: viewportProxy.size.width - 36, reader: reader)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.top, 18)
            }

            WordiestBottomBar(palette: palette) {
                Button("Back") { model.returnToSplash() }
                    .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .tint(palette.foreground)
        .alert("Confirm", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    model.historyStore.delete(id: pendingDelete.id)
                }
                pendingDelete = nil
            }
        } message: {
            Text("Delete history item?")
        }
    }

    private func sparklineHeader(palette: ColorPalette) -> some View {
        let entriesOldestFirst = model.historyStore.entries.reversed()
        let ratings = entriesOldestFirst.map { Double($0.newRatingX10) / 10.0 }
        let expectedDelta = entriesOldestFirst.map { Double($0.newRatingX10 - $0.ratingX10) / 10.0 }
        let mm = SparklineMath.ratingMinMax(ratings: ratings)

        return VStack(spacing: 8) {
            HStack {
                Text("Rating History")
                    .foregroundStyle(palette.foreground)
                    .font(.headline)
                Spacer()
                Text("\(Int(mm.max))")
                    .foregroundStyle(palette.foreground)
                    .font(.footnote)
            }

            SparklineView(
                palette: palette,
                ratings: ratings,
                expectedDelta: expectedDelta,
                highlightStart: highlightStart,
                highlightEnd: highlightEnd
            )

            HStack {
                Text("Oldest")
                    .foregroundStyle(palette.foreground)
                    .font(.footnote)
                Spacer()
                Text("\(Int(mm.min))")
                    .foregroundStyle(palette.foreground)
                    .font(.footnote)
                Spacer()
                Text("Newest")
                    .foregroundStyle(palette.foreground)
                    .font(.footnote)
            }
        }
    }

    private func openReview(entry: HistoryEntry) {
        guard let tiles = HistoryJSON.decodeMatchTiles(entry.matchDataJSON) else { return }
        guard let samples = HistoryJSON.decodeScoreSamples(entry.scoreListJSON) else { return }

        let match = Match(tiles: tiles, scoreSamples: samples)
        var update = UpdateRating(rating: Double(entry.ratingX10) / 10.0, ratingDeviation: 0.0)
        let opponents: [UpdateRating.ScoreRating] = match.scoreSamples.map { sample in
            UpdateRating.ScoreRating(
                score: sample.score,
                rating: Double(sample.ratingX10) / 10.0,
                wordsEncoding: sample.wordsEncoding
            )
        }
        update.update(playerScore: entry.score, opponents: opponents)
        model.presentScore(
            AppModel.ScoreContext(
                matchIndex: Int(entry.matchId) ?? 0,
                match: match,
                playerEncoding: entry.wordsEncoding,
                playerScore: entry.score,
                percentile: Int(Double(entry.percentileX10) / 10.0),
                upsetWins: update.upsetWins,
                expectedLosses: update.expectedLosses,
                expectedWins: update.expectedWins,
                upsetLosses: update.upsetLosses,
                matchCountBefore: max(0, model.settings.numMatches - 1),
                oldRating: Double(entry.ratingX10) / 10.0,
                newRating: Double(entry.newRatingX10) / 10.0,
                isReview: true
            ),
            prepareMatchReview: true
        )
    }

    private func scrub(toX x: CGFloat, width: CGFloat, reader: ScrollViewProxy) {
        guard width > 0 else { return }
        let count = model.historyStore.entries.count
        guard count > 0 else { return }

        let fraction = min(max((x - 18) / width, 0), 1)
        let selection = Int(round(Double(count) * (1.0 - fraction)))
        let index = min(max(selection, 0), count - 1)
        let entry = model.historyStore.entries[index]
        withAnimation(.easeOut(duration: 0.15)) {
            reader.scrollTo(entry.id, anchor: .top)
        }
    }

    private func updateHighlight(viewport: CGRect) {
        let count = model.historyStore.entries.count
        guard count > 0 else {
            highlightStart = nil
            highlightEnd = nil
            return
        }

        var visible: [Int] = []
        visible.reserveCapacity(16)
        for (index, frame) in visibleRowFrames {
            if frame.intersects(viewport) {
                visible.append(index)
            }
        }
        guard let first = visible.min(), let last = visible.max() else {
            highlightStart = nil
            highlightEnd = nil
            return
        }

        let start = (count - 1) - last
        let end = (count - 1) - first
        highlightStart = start
        highlightEnd = end
    }
}

private struct HistoryRowFramePreferenceKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
