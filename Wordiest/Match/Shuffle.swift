import Foundation

enum Shuffle {
    static func shuffled(state: RackState, randomIndex: (Int) -> Int) -> RackState {
        var combined = state.bank1 + state.bank2

        if combined.count > 1 {
            var shuffled = combined
            fisherYatesShuffle(&shuffled, randomIndex: randomIndex)

            var adjusted: [Int] = []
            adjusted.reserveCapacity(shuffled.count)

            for original in combined {
                if shuffled.count > 1, shuffled[0] == original {
                    shuffled.swapAt(0, 1)
                }
                adjusted.append(shuffled.removeFirst())
            }

            if adjusted.last == combined.last {
                let swapIndex = randomIndex(adjusted.count - 1)
                adjusted.swapAt(adjusted.count - 1, swapIndex)
            }

            combined = adjusted
        }

        let bank1Size = (combined.count + 1) / 2
        return RackState(
            word1: state.word1,
            word2: state.word2,
            bank1: Array(combined.prefix(bank1Size)),
            bank2: Array(combined.dropFirst(bank1Size))
        )
    }

    static func shuffled(state: RackState) -> RackState {
        var rng = SystemRandomNumberGenerator()
        return shuffled(state: state, randomIndex: { upperBound in
            precondition(upperBound > 0)
            return Int(rng.next() % UInt64(upperBound))
        })
    }

    private static func fisherYatesShuffle(_ values: inout [Int], randomIndex: (Int) -> Int) {
        guard values.count > 1 else { return }
        for i in stride(from: values.count - 1, through: 1, by: -1) {
            let j = randomIndex(i + 1)
            values.swapAt(i, j)
        }
    }
}

