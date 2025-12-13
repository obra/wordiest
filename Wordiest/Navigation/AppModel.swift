import Foundation
import WordiestCore

@MainActor
final class AppModel: ObservableObject {
    enum Route: Equatable {
        case splash
        case match
        case score(ScoreContext)
        case history
        case credits
        case help
    }

    struct GameAssets: Sendable {
        var matchStore: MatchDataStore
        var definitions: Definitions
    }

    struct ScoreContext: Equatable {
        var matchIndex: Int
        var match: Match
        var playerEncoding: UInt64
        var playerScore: Int
        var percentile: Int
        var oldRating: Double
        var newRating: Double
    }

    @Published var route: Route = .splash
    @Published private(set) var isLoadingAssets: Bool = true

    let settings: AppSettings
    let historyStore: HistoryStore
    let scene: GameScene

    private(set) var assets: GameAssets?

    init(settings: AppSettings = AppSettings(), historyStore: HistoryStore = HistoryStore()) {
        self.settings = settings
        self.historyStore = historyStore
        self.scene = GameScene(size: .zero)

        Task { await loadAssets() }
    }

    func startPlay() {
        route = .match
    }

    func showHistory() {
        route = .history
    }

    func showCredits() {
        route = .credits
    }

    func showHelp() {
        route = .help
    }

    func returnToSplash() {
        route = .splash
    }

    func applySettingsToScene() {
        scene.soundEnabled = settings.soundEnabled
    }

    func configureSceneIfReady(size: CGSize) {
        guard let assets else { return }
        scene.configure(size: size)
        scene.setAssets(matchStore: assets.matchStore, definitions: assets.definitions)
        applySettingsToScene()
    }

    func handleConfirmedSubmission() {
        guard let matchIndex = scene.currentMatchIndex, let match = scene.currentMatch else { return }
        guard let encoding = scene.currentWordsEncoding() else { return }

        let playerScore = scene.currentScoreValue()

        let oldRating = settings.rating
        var update = UpdateRating(rating: settings.rating, ratingDeviation: settings.ratingDeviation)
        let opponents: [UpdateRating.ScoreRating] = match.scoreSamples.map { sample in
            UpdateRating.ScoreRating(
                score: sample.score,
                rating: Double(sample.ratingX10) / 10.0,
                wordsEncoding: sample.wordsEncoding
            )
        }
        update.update(playerScore: playerScore, opponents: opponents)

        settings.numMatches += 1
        settings.cumulativeScore += Int64(playerScore)
        settings.rating = update.newRating

        let entry = HistoryEntry(
            matchId: String(matchIndex),
            matchDataJSON: HistoryJSON.encodeMatchTiles(match.tiles),
            scoreListJSON: HistoryJSON.encodeScoreSamples(match.scoreSamples),
            wordsEncoding: encoding,
            score: playerScore,
            ratingX10: Int(oldRating * 10.0),
            newRatingX10: Int(update.newRating * 10.0),
            percentileX10: Int(update.percentile * 10.0),
            timestamp: HistoryJSON.gmtTimestampNow()
        )
        historyStore.append(entry)

        route = .score(
            ScoreContext(
                matchIndex: matchIndex,
                match: match,
                playerEncoding: encoding,
                playerScore: playerScore,
                percentile: Int(update.percentile),
                oldRating: oldRating,
                newRating: update.newRating
            )
        )
    }

    func finishScoreAndAdvance() {
        scene.advanceToNextMatch()
        route = .match
    }

    private func loadAssets() async {
        isLoadingAssets = true
        defer { isLoadingAssets = false }

        guard
            let matchURL = Bundle.main.url(forResource: "matchdata", withExtension: "packed"),
            let idxURL = Bundle.main.url(forResource: "words", withExtension: "idx"),
            let defURL = Bundle.main.url(forResource: "words", withExtension: "def")
        else {
            assets = nil
            return
        }

        do {
            let store = try MatchDataStore(data: try Data(contentsOf: matchURL))
            let defs = Definitions(indexData: try Data(contentsOf: idxURL), definitionsData: try Data(contentsOf: defURL))
            assets = GameAssets(matchStore: store, definitions: defs)
        } catch {
            assets = nil
        }
    }
}

