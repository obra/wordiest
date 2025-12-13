import Foundation

enum ScoreSummary {
    static func scoreText(score: Int, percentile: Int) -> String {
        let plural = score == 1 ? "" : "s"
        return "You scored \(score) point\(plural), beating \(percentile)% of other players."
    }

    static func ratingText(old: Double, new: Double, matchCount: Int) -> String {
        let oldText = formatTenths(old)
        let newText = formatTenths(new)

        if matchCount == 0 {
            return "Your new rating is \(newText)!"
        }

        let delta = formatTenths(abs(new - old))
        if new > old {
            return "Your \(oldText) rating grew by \(delta) to \(newText)!"
        }
        if new < old {
            return "Your \(oldText) rating fell by \(delta) to \(newText)."
        }
        return "No rating change, still \(oldText)."
    }

    static func expectedLossesText(count: Int) -> String {
        let plural = count == 1 ? "" : "s"
        return "\(count) higher rated player\(plural) beat you."
    }

    static func upsetLossesText(count: Int) -> String {
        let plural = count == 1 ? "" : "s"
        return "\(count) lower rated player\(plural) beat you."
    }

    static func expectedWinsText(count: Int) -> String {
        let plural = count == 1 ? "" : "s"
        return "You beat \(count) lower rated player\(plural)."
    }

    static func upsetWinsText(count: Int) -> String {
        let plural = count == 1 ? "" : "s"
        return "You beat \(count) higher rated player\(plural)."
    }

    private static func formatTenths(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
