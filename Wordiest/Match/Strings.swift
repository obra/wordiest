enum MatchStrings {
    static let reviewBanner = "You are reviewing a previously played game. You can play with it, but may not submit new words."

    static func totalScore(_ score: Int) -> String {
        let plural = score == 1 ? "" : "s"
        return "Total \(score) point\(plural)"
    }

    static func totalScoreWithBest(_ score: Int, best: Int) -> String {
        if best > score {
            return "\(totalScore(score)) (best \(best))"
        }
        return totalScore(score)
    }
}
