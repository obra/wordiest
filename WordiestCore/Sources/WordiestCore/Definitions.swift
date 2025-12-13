import Foundation

public final class Definitions: @unchecked Sendable {
    public struct Definition: Equatable, Sendable {
        public var word: String
        public var lookupWord: String
        public var seeWord: String?
        public var partOfSpeech: String
        public var definition: String
    }

    public enum Error: Swift.Error, Equatable {
        case truncatedData
        case malformedTrie
        case invalidWordEncoding
        case invalidDefinitionEncoding
    }

    private let indexData: Data
    private let definitionsData: Data

    public init(indexData: Data, definitionsData: Data) {
        self.indexData = indexData
        self.definitionsData = definitionsData
    }

    public func definition(for word: String) throws -> Definition? {
        let normalized = word.lowercased()
        guard !normalized.isEmpty else { return nil }

        guard let raw = try rawDefinition(for: normalized) else { return nil }

        guard let pipe = raw.firstIndex(of: "|") else { return nil }
        let partOfSpeech = String(raw[..<pipe])

        guard let primary = partOfSpeechDefinition(raw, partOfSpeech: partOfSpeech) else { return nil }

        var lookupWord = normalized
        var seeWord: String?
        var finalDef = primary

        if finalDef.hasPrefix("@") {
            var target = String(finalDef.dropFirst())
            seeWord = target
            if target.hasPrefix("!") {
                target = String(target.dropFirst())
                seeWord = target
                lookupWord = target
            }
            guard let redirectedRaw = try rawDefinition(for: target) else { return nil }
            guard let redirected = partOfSpeechDefinition(redirectedRaw, partOfSpeech: partOfSpeech) else { return nil }
            finalDef = redirected
        }

        return Definition(
            word: normalized,
            lookupWord: lookupWord,
            seeWord: seeWord,
            partOfSpeech: partOfSpeech,
            definition: finalDef
        )
    }

    private func partOfSpeechDefinition(_ raw: String, partOfSpeech: String) -> String? {
        let parts = raw.split(separator: "|", omittingEmptySubsequences: false)
        var idx = 0
        while idx + 1 < parts.count {
            let key = String(parts[idx])
            let value = String(parts[idx + 1])
            if key == partOfSpeech {
                return value
            }
            idx += 2
        }
        return nil
    }

    private func rawDefinition(for word: String) throws -> String? {
        guard indexData.count >= 5 else { throw Error.truncatedData }

        var (nodeOffset, _) = try decodeVarInt(from: indexData, offset: 4)

        for scalar in word.unicodeScalars {
            guard scalar.isASCII else { throw Error.invalidWordEncoding }
            let targetByte = UInt8(scalar.value)

            guard nodeOffset >= 0, nodeOffset < indexData.count else { throw Error.malformedTrie }
            let header = indexData[nodeOffset]
            guard (header & 0x40) != 0 else { throw Error.malformedTrie }

            let childCount = Int(header & 0x3F)
            var cursor = nodeOffset + 1

            if (header & 0x80) != 0 {
                let (_, len) = try decodeVarInt(from: indexData, offset: cursor)
                cursor += len
            }

            var found = false
            for _ in 0..<childCount {
                guard cursor < indexData.count else { throw Error.truncatedData }
                let childByte = indexData[cursor]
                cursor += 1

                let (delta, len) = try decodeVarInt(from: indexData, offset: cursor)
                cursor += len

                if childByte == targetByte {
                    nodeOffset -= delta
                    found = true
                    break
                }
            }

            if !found {
                return nil
            }
        }

        guard nodeOffset >= 0, nodeOffset < indexData.count else { throw Error.malformedTrie }
        let header = indexData[nodeOffset]
        guard (header & 0x40) != 0 else { throw Error.malformedTrie }
        guard (header & 0x80) != 0 else { return nil }

        let (definitionOffset, _) = try decodeVarInt(from: indexData, offset: nodeOffset + 1)
        let defOffset = definitionOffset

        let (defLen, defLenBytes) = try decodeVarInt(from: definitionsData, offset: defOffset)
        let start = defOffset + defLenBytes
        let end = start + defLen
        guard start >= 0, end <= definitionsData.count else { throw Error.invalidDefinitionEncoding }

        let bytes = definitionsData.subdata(in: start..<end)
        if let s = String(data: bytes, encoding: .utf8) {
            return s
        }
        if let s = String(data: bytes, encoding: .isoLatin1) {
            return s
        }
        return nil
    }

    private func decodeVarInt(from data: Data, offset: Int) throws -> (value: Int, byteCount: Int) {
        var value = 0
        var multiplier = 1
        var idx = 0

        while true {
            let i = offset + idx
            guard i < data.count else { throw Error.truncatedData }
            let b = data[i]
            value += Int(b & 0x7F) * multiplier
            idx += 1
            multiplier *= 128
            if (b & 0x80) != 0 {
                break
            }
        }

        return (value, idx)
    }
}
