import WordiestCore

enum ReviewPlacement {
    static func rackState(tileCount: Int, encoding: UInt64) -> RackState? {
        guard tileCount > 0 else { return nil }
        guard let decoded = try? SubsetEncoding.decode(encoding, tileCount: tileCount) else { return nil }

        let used = Set(decoded.word1).union(decoded.word2)
        guard used.count == decoded.word1.count + decoded.word2.count else { return nil }

        var bank1: [Int] = []
        bank1.reserveCapacity(tileCount)
        for i in 0..<tileCount {
            if !used.contains(i) { bank1.append(i) }
        }

        var bank2: [Int] = []
        while bank1.count > 7 {
            bank2.append(bank1.removeLast())
        }

        return RackState(word1: decoded.word1, word2: decoded.word2, bank1: bank1, bank2: bank2)
    }
}

