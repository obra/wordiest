import Foundation

public enum SubsetEncoding {
    public enum Error: Swift.Error, Equatable {
        case invalidTileCount(Int)
        case invalidNibble(UInt8)
        case multipleDelimiters
        case tileIndexOutOfRange(Int)
        case duplicateTileIndex(Int)
    }

    public static func decode(_ encoded: UInt64, tileCount: Int) throws -> (word1: [Int], word2: [Int]) {
        guard tileCount > 0, tileCount <= 14 else { throw Error.invalidTileCount(tileCount) }

        if encoded == 0 {
            return ([], [])
        }

        var nibbles: [UInt8] = []
        nibbles.reserveCapacity(16)

        var started = false
        for shift in stride(from: 60, through: 0, by: -4) {
            let nibble = UInt8((encoded >> UInt64(shift)) & 0xF)
            if !started {
                if nibble == 0 { continue }
                started = true
            }
            nibbles.append(nibble)
        }

        var sawDelimiter = false
        var word1: [Int] = []
        var word2: [Int] = []
        word1.reserveCapacity(7)
        word2.reserveCapacity(7)

        var used: Set<Int> = []
        used.reserveCapacity(14)

        for nibble in nibbles {
            if nibble == 0xF {
                if sawDelimiter { throw Error.multipleDelimiters }
                sawDelimiter = true
                continue
            }

            guard nibble != 0 else { throw Error.invalidNibble(nibble) }

            let index1Based = Int(nibble)
            guard index1Based <= tileCount else { throw Error.tileIndexOutOfRange(index1Based - 1) }

            let index0Based = index1Based - 1
            if used.contains(index0Based) { throw Error.duplicateTileIndex(index0Based) }
            used.insert(index0Based)

            if sawDelimiter {
                word2.append(index0Based)
            } else {
                word1.append(index0Based)
            }
        }

        return (word1, word2)
    }

    public static func encode(word1: [Int], word2: [Int]) throws -> UInt64 {
        var used: Set<Int> = []
        used.reserveCapacity(word1.count + word2.count)

        var nibbles: [UInt8] = []
        nibbles.reserveCapacity(word1.count + word2.count + 1)

        func appendWord(_ word: [Int]) throws {
            for index0Based in word {
                guard index0Based >= 0 else { throw Error.tileIndexOutOfRange(index0Based) }
                guard index0Based < 14 else { throw Error.tileIndexOutOfRange(index0Based) }
                if used.contains(index0Based) { throw Error.duplicateTileIndex(index0Based) }
                used.insert(index0Based)
                nibbles.append(UInt8(index0Based + 1))
            }
        }

        try appendWord(word1)
        if !word2.isEmpty {
            nibbles.append(0xF)
        }
        try appendWord(word2)

        var encoded: UInt64 = 0
        for nibble in nibbles {
            encoded = (encoded << 4) | UInt64(nibble)
        }
        return encoded
    }
}

