enum MatchStrings {
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

