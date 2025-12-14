import Foundation
import UIKit
import WordiestCore

@MainActor
final class AppModel: ObservableObject {
    enum Route: Equatable {
        case splash
        case match
        case score(ScoreContext)
        case history
        case leaders
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
        var upsetWins: Int
        var expectedLosses: Int
        var expectedWins: Int
        var upsetLosses: Int
        var matchCountBefore: Int
        var oldRating: Double
        var newRating: Double
        var isReview: Bool
    }

    @Published var route: Route = .splash
    @Published private(set) var isLoadingAssets: Bool = true

    let settings: AppSettings
    let historyStore: HistoryStore
    let gameCenter: GameCenterSubmitting
    let scene: GameScene

    private(set) var assets: GameAssets?
    private(set) var matchReviewContext: ScoreContext?

    init(settings: AppSettings = AppSettings(), historyStore: HistoryStore = HistoryStore(), gameCenter: GameCenterSubmitting = GameCenterManager()) {
        self.settings = settings
        self.historyStore = historyStore
        self.gameCenter = gameCenter
        self.scene = GameScene(size: .zero)

        gameCenter.authenticateIfNeeded()
        Task { await loadAssets() }
    }

    func startPlay() {
        scene.isReview = false
        matchReviewContext = nil
        route = .match
    }

    func showHistory() {
        route = .history
    }

    func showLeaders() {
        route = .leaders
    }

    func showCredits() {
        route = .credits
    }

    func showHelp() {
        route = .help
    }

    func returnToSplash() {
        scene.isReview = false
        matchReviewContext = nil
        route = .splash
    }

    func showMatchReviewFromScore() {
        route = .match
    }

    func returnToScoreFromMatchReview() {
        guard let context = matchReviewContext else {
            returnToSplash()
            return
        }
        route = .score(context)
    }

    func applySettingsToScene() {
        scene.soundEnabled = settings.soundEnabled
        scene.applyPalette(settings.palette)
    }

    func resetRatingAndHistory() {
        settings.resetRatingAndStats()
        historyStore.clear()
        applySettingsToScene()
    }

    func openPrivacyPolicy() {
        guard let url = URL(string: "https://concreterose.github.io/privacypolicy.html") else { return }
        UIApplication.shared.open(url)
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

        let matchCountBefore = settings.numMatches
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
        submitLeaderboardsAfterMatch(playerScore: playerScore, newRating: update.newRating)

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

        presentScore(
            ScoreContext(
                matchIndex: matchIndex,
                match: match,
                playerEncoding: encoding,
                playerScore: playerScore,
                percentile: Int(update.percentile),
                upsetWins: update.upsetWins,
                expectedLosses: update.expectedLosses,
                expectedWins: update.expectedWins,
                upsetLosses: update.upsetLosses,
                matchCountBefore: matchCountBefore,
                oldRating: oldRating,
                newRating: update.newRating,
                isReview: false
            ),
            prepareMatchReview: false
        )
    }

    func submitLeaderboardsAfterMatch(playerScore: Int, newRating: Double) {
        gameCenter.submit(
            scoreSubmissions: GameCenterLeaderboards.scoreSubmissions(
                cumulativeScore: settings.cumulativeScore,
                bestRoundScore: playerScore,
                rating: newRating
            )
        )
    }

    func startNewMatchFromScore() {
        matchReviewContext = nil
        scene.isReview = false
        scene.advanceToNextMatch()
        route = .match
    }

    func presentScore(_ context: ScoreContext, prepareMatchReview: Bool) {
        matchReviewContext = context
        scene.isReview = true
        if prepareMatchReview {
            scene.loadReviewMatch(matchIndex: context.matchIndex, match: context.match, wordsEncoding: context.playerEncoding)
        }
        route = .score(context)
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
