import Foundation

struct GameCenterScoreSubmission: Equatable, Hashable {
    var leaderboardID: String
    var score: Int
}

enum GameCenterLeaderboards {
    static let totalPointsAllTimeID = "total_points_all_time"
    static let bestRoundScoreID = "best_round_score"
    static let ratingPercentID = "rating_percent"

    static func scoreSubmissions(cumulativeScore: Int64, bestRoundScore: Int, rating: Double) -> [GameCenterScoreSubmission] {
        let ratingPercent = Int(rating.rounded())
        let safeCumulative = Int(truncatingIfNeeded: cumulativeScore)

        return [
            GameCenterScoreSubmission(leaderboardID: totalPointsAllTimeID, score: safeCumulative),
            GameCenterScoreSubmission(leaderboardID: bestRoundScoreID, score: bestRoundScore),
            GameCenterScoreSubmission(leaderboardID: ratingPercentID, score: ratingPercent),
        ]
    }
}

