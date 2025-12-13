final class BestTracker {
    private(set) var bestScore: Int = 0
    private(set) var bestState: RackState?

    func reset() {
        bestScore = 0
        bestState = nil
    }

    func observe(state: RackState, bestScoreCandidate: Int) {
        guard bestScoreCandidate > bestScore else { return }
        bestScore = bestScoreCandidate
        bestState = state
    }

    func restoreIfBetterThanCurrent(currentScore: Int) -> RackState? {
        guard let bestState else { return nil }
        guard bestScore > currentScore else { return nil }
        return bestState
    }
}

struct RackState: Equatable {
    var word1: [Int]
    var word2: [Int]
    var bank1: [Int]
    var bank2: [Int]
}

