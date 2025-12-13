import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var colorPaletteIndex: Int {
        didSet { defaults.set(colorPaletteIndex, forKey: Keys.colorPaletteIndex) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    @Published var rating: Double {
        didSet { defaults.set(rating, forKey: Keys.rating) }
    }

    @Published var ratingDeviation: Double {
        didSet { defaults.set(ratingDeviation, forKey: Keys.ratingDeviation) }
    }

    @Published var numMatches: Int {
        didSet { defaults.set(numMatches, forKey: Keys.numMatches) }
    }

    @Published var cumulativeScore: Int64 {
        didSet { defaults.set(cumulativeScore, forKey: Keys.cumulativeScore) }
    }

    private(set) var userId: UInt64

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.colorPaletteIndex = defaults.object(forKey: Keys.colorPaletteIndex) as? Int ?? 1
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.rating = defaults.object(forKey: Keys.rating) as? Double ?? 50.0
        self.ratingDeviation = defaults.object(forKey: Keys.ratingDeviation) as? Double ?? 0.0
        self.numMatches = defaults.object(forKey: Keys.numMatches) as? Int ?? 0
        self.cumulativeScore = defaults.object(forKey: Keys.cumulativeScore) as? Int64 ?? 0

        if let existing = defaults.object(forKey: Keys.userId) as? NSNumber {
            self.userId = existing.uint64Value
        } else {
            let generated = Self.generateUserId()
            self.userId = generated
            defaults.set(generated, forKey: Keys.userId)
        }
    }

    func reset() {
        resetRatingAndStats()
    }

    func resetRatingAndStats() {
        rating = 50.0
        ratingDeviation = 0.0
        numMatches = 0
        cumulativeScore = 0
    }

    var palette: ColorPalette {
        ColorPalette.palette(index: colorPaletteIndex)
    }

    private enum Keys {
        static let colorPaletteIndex = "colorPaletteIndex"
        static let soundEnabled = "soundEnabled"
        static let rating = "rating"
        static let ratingDeviation = "ratingDeviation"
        static let numMatches = "numMatches"
        static let cumulativeScore = "cumulativeScore"
        static let userId = "userId"
    }

    private static func generateUserId() -> UInt64 {
        let uuid = UUID()
        // Use UUID bytes as a source of entropy.
        let bits = withUnsafeBytes(of: uuid.uuid) { raw -> UInt64 in
            let bytes = Array(raw)
            var a: UInt64 = 0
            var b: UInt64 = 0
            for i in 0..<8 { a = (a << 8) | UInt64(bytes[i]) }
            for i in 8..<16 { b = (b << 8) | UInt64(bytes[i]) }
            return a ^ b
        }
        if bits == 0 || bits == UInt64.max { return 1 }
        return bits
    }
}
