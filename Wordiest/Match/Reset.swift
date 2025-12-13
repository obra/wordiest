enum Reset {
    static func apply(
        state: RackState,
        clearOnlyInvalid: Bool,
        isWord1Valid: Bool,
        isWord2Valid: Bool,
        shuffle: (RackState) -> RackState
    ) -> RackState {
        var removed: [Int] = []
        removed.reserveCapacity(state.word1.count + state.word2.count)

        var newWord1 = state.word1
        var newWord2 = state.word2

        if clearOnlyInvalid {
            if !isWord1Valid {
                removed.append(contentsOf: newWord1)
                newWord1.removeAll(keepingCapacity: true)
            }
            if !isWord2Valid {
                removed.append(contentsOf: newWord2)
                newWord2.removeAll(keepingCapacity: true)
            }
        } else {
            removed.append(contentsOf: newWord1)
            removed.append(contentsOf: newWord2)
            newWord1.removeAll(keepingCapacity: true)
            newWord2.removeAll(keepingCapacity: true)
        }

        if removed.isEmpty {
            return shuffle(state)
        }

        var bank1 = state.bank1
        var bank2 = state.bank2
        bank1.reserveCapacity(bank1.count + removed.count)
        bank2.reserveCapacity(bank2.count + removed.count)

        for tile in removed {
            if bank1.count <= bank2.count {
                bank1.append(tile)
            } else {
                bank2.append(tile)
            }
        }

        return RackState(word1: newWord1, word2: newWord2, bank1: bank1, bank2: bank2)
    }
}

