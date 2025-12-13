import Foundation

struct HistoryEntry: Codable, Equatable, Identifiable {
    var id: String { "\(matchId)|\(timestamp)" }

    var matchId: String
    var matchDataJSON: String
    var scoreListJSON: String

    var wordsEncoding: UInt64
    var score: Int

    var ratingX10: Int
    var newRatingX10: Int
    var percentileX10: Int

    var timestamp: String
}

