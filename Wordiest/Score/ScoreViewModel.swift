import Foundation
import WordiestCore

@MainActor
final class ScoreViewModel: ObservableObject {
    @Published private(set) var scoreText: String = ""
    @Published private(set) var ratingText: String = ""

    func update(score: Int, oldRating: Double, ratingUpdate: UpdateRating, matchCount: Int) {
        scoreText = ScoreSummary.scoreText(score: score, percentile: Int(ratingUpdate.percentile))
        ratingText = ScoreSummary.ratingText(old: oldRating, new: ratingUpdate.newRating, matchCount: matchCount)
    }
}
