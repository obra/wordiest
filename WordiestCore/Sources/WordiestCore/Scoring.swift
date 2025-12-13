import Foundation

public enum WordiestScoring {
    public static func scoreWord(_ tiles: [Tile]) throws -> Int {
        var wordMultiplier = 1
        var sum = 0

        for tile in tiles {
            var letterMultiplier = 1
            if let bonus = tile.bonus {
                let parsed = try parseBonus(bonus)
                switch parsed.kind {
                case .word:
                    wordMultiplier *= parsed.multiplier
                case .letter:
                    letterMultiplier *= parsed.multiplier
                }
            }
            sum += tile.value * letterMultiplier
        }

        return sum * wordMultiplier
    }

    public static func scoreMove(word1: [Tile], word2: [Tile]) throws -> Int {
        try scoreWord(word1) + scoreWord(word2)
    }

    private enum BonusKind {
        case word
        case letter
    }

    private struct ParsedBonus {
        var multiplier: Int
        var kind: BonusKind
    }

    private static func parseBonus(_ bonus: String) throws -> ParsedBonus {
        let trimmed = bonus.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { throw BonusParseError.invalidFormat(bonus) }

        let multChar = trimmed.prefix(1)
        let kindChar = trimmed.dropFirst().prefix(1).lowercased()

        guard let multiplier = Int(multChar), multiplier > 0 else {
            throw BonusParseError.invalidFormat(bonus)
        }

        switch kindChar {
        case "w":
            return ParsedBonus(multiplier: multiplier, kind: .word)
        case "l":
            return ParsedBonus(multiplier: multiplier, kind: .letter)
        default:
            throw BonusParseError.unknownKind(bonus)
        }
    }

    public enum BonusParseError: Error, Equatable {
        case invalidFormat(String)
        case unknownKind(String)
    }
}

