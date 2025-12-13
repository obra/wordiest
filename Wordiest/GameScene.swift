import SpriteKit
import WordiestCore

@MainActor
final class GameScene: SKScene {
    private enum Row: CaseIterable {
        case word1
        case word2
        case bank1
        case bank2
    }

    private let tileGap: CGFloat = 10
    private let scenePadding: CGFloat = 16
    private let bankCapacity = 7

    private var matchStore: MatchDataStore?
    private var definitions: Definitions?
    private var nextMatchIndex = 0

    private var tileNodes: [TileNode] = []
    private var tilesByRow: [Row: [TileNode]] = [:]

    private var dragging: (node: TileNode, offset: CGPoint, baseScale: CGFloat)?
    private let bestTracker = BestTracker()
    private var currentScore: Int = 0

    private let scoreLabel = SKLabelNode(fontNamed: "IstokWeb-Bold")
    private let definition1Label = SKLabelNode(fontNamed: "IstokWeb-Bold")
    private let definition2Label = SKLabelNode(fontNamed: "IstokWeb-Bold")

    var onRequestOpenWiktionary: ((String) -> Void)?

    private var lastWord1Definition: Definitions.Definition?
    private var lastWord2Definition: Definitions.Definition?

    var isReview: Bool = false

    func configure(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        if self.size != size {
            self.size = size
            layoutAll(animated: false)
        }
        if scaleMode != .resizeFill {
            scaleMode = .resizeFill
        }
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black

        if tilesByRow.isEmpty {
            for row in Row.allCases {
                tilesByRow[row] = []
            }
        }

        configureLabels()
        loadAssetsIfNeeded()
        loadNextMatch()
    }

    func shuffle() {
        let state = currentRackState()
        applyRackState(Shuffle.shuffled(state: state))
        rebalanceBanks()
        layoutAll(animated: true)
        run(SKAction.playSoundFileNamed("pickup.mp3", waitForCompletion: false))
    }

    func resetWords() {
        resetWords(clearOnlyInvalid: false)
    }

    func resetWords(clearOnlyInvalid: Bool) {
        let state = currentRackState()
        let validity = currentWordValidity()

        let reset = Reset.apply(
            state: state,
            clearOnlyInvalid: clearOnlyInvalid,
            isWord1Valid: validity.isWord1Valid,
            isWord2Valid: validity.isWord2Valid,
            shuffle: { Shuffle.shuffled(state: $0) }
        )

        applyRackState(reset)
        rebalanceBanks()
        layoutAll(animated: true)
        run(SKAction.playSoundFileNamed("pickup.mp3", waitForCompletion: false))
    }

    func submit() {
        if isReview { return }
        loadNextMatch()
        run(SKAction.playSoundFileNamed("drop.mp3", waitForCompletion: false))
    }

    func currentWords() -> (word1: String, word2: String) {
        let word1 = (tilesByRow[.word1] ?? []).map { $0.tile.letter }.joined()
        let word2 = (tilesByRow[.word2] ?? []).map { $0.tile.letter }.joined()
        return (word1, word2)
    }

    func currentValidWordCount() -> Int {
        var count = 0
        if lastWord1Definition != nil { count += 1 }
        if lastWord2Definition != nil { count += 1 }
        return count
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragging == nil, let touch = touches.first else { return }
        let point = touch.location(in: self)

        if nodes(at: point).contains(scoreLabel) {
            if let restore = bestTracker.restoreIfBetterThanCurrent(currentScore: currentScore) {
                applyRackState(restore)
                rebalanceBanks()
                layoutAll(animated: true)
            }
            return
        }

        if nodes(at: point).contains(definition1Label), let def = lastWord1Definition {
            onRequestOpenWiktionary?(def.lookupWord)
            return
        }
        if nodes(at: point).contains(definition2Label), let def = lastWord2Definition {
            onRequestOpenWiktionary?(def.lookupWord)
            return
        }

        guard let node = tileNode(at: point) else { return }

        removeTileFromRows(node)

        let offset = CGPoint(x: point.x - node.position.x, y: point.y - node.position.y)
        node.zPosition = 10
        let baseScale = node.xScale
        node.setScale(baseScale * DragConstants.draggingScaleMultiplier)
        dragging = (node, offset, baseScale)
        run(SKAction.playSoundFileNamed("pickup.mp3", waitForCompletion: false))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging else { return }
        let point = touch.location(in: self)
        dragging.node.position = CGPoint(x: point.x - dragging.offset.x, y: point.y - dragging.offset.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging else { return }
        let point = touch.location(in: self)
        drop(dragging.node, at: point)
        self.dragging = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging else { return }
        let point = touch.location(in: self)
        drop(dragging.node, at: point)
        self.dragging = nil
    }

    private func drop(_ node: TileNode, at point: CGPoint) {
        let row = closestRow(to: point)
        tilesByRow[row, default: []].append(node)

        if row == .bank1 || row == .bank2 {
            rebalanceBanks()
        }

        node.zPosition = 1
        layoutAll(animated: true)
        run(SKAction.playSoundFileNamed("drop.mp3", waitForCompletion: false))
    }

    private func removeTileFromRows(_ node: TileNode) {
        for row in Row.allCases {
            tilesByRow[row]?.removeAll { $0 === node }
        }
        layoutAll(animated: true)
    }

    private func tileNode(at point: CGPoint) -> TileNode? {
        let nodes = nodes(at: point)
        for node in nodes {
            if let tile = node as? TileNode { return tile }
            if let tile = node.parent as? TileNode { return tile }
        }
        return nil
    }

    // MARK: - Layout

    private func configureLabels() {
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = 20
        if scoreLabel.parent == nil { addChild(scoreLabel) }

        for label in [definition1Label, definition2Label] {
            label.fontSize = 14
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .top
            label.zPosition = 20
            label.numberOfLines = 3
            label.preferredMaxLayoutWidth = max(200, size.width - (scenePadding * 2))
            if label.parent == nil { addChild(label) }
        }
    }

    private func layoutAll(animated: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        let scoreY = size.height - scenePadding
        scoreLabel.position = CGPoint(x: size.width / 2, y: scoreY)

        let rowYs = rowYPositions()
        let tileSize = baseTileSize()

        for row in Row.allCases {
            let tiles = tilesByRow[row] ?? []
            layoutRow(tiles, atY: rowYs[row] ?? 0, baseTileSize: tileSize, animated: animated)
        }

        definition1Label.position = CGPoint(x: size.width / 2, y: (rowYs[.word1] ?? 0) - tileSize.height * 0.75)
        definition2Label.position = CGPoint(x: size.width / 2, y: (rowYs[.word2] ?? 0) - tileSize.height * 0.75)

        updateScoreAndDefinitions()
    }

    private func layoutRow(_ tiles: [TileNode], atY y: CGFloat, baseTileSize: CGSize, animated: Bool) {
        let count = max(tiles.count, 1)
        let maxWidth = size.width - (scenePadding * 2)
        let neededWidth = (CGFloat(count) * baseTileSize.width) + (CGFloat(count - 1) * tileGap)
        let scale = min(1, maxWidth / neededWidth)

        let tileWidth = baseTileSize.width * scale
        let tileHeight = baseTileSize.height * scale

        let totalWidth = (CGFloat(tiles.count) * tileWidth) + (CGFloat(max(tiles.count - 1, 0)) * tileGap)
        var x = (size.width - totalWidth) / 2 + (tileWidth / 2)

        for tile in tiles {
            let target = CGPoint(x: x, y: y)
            x += tileWidth + tileGap

            if animated {
                let duration: TimeInterval = 0.20

                let move = SKAction.move(to: target, duration: duration)
                move.timingFunction = Self.overshootTimingFunction()

                let scaleAction = SKAction.scale(to: scale, duration: duration)
                scaleAction.timingFunction = Self.overshootTimingFunction()

                tile.run(.group([move, scaleAction]), withKey: "layout")
            } else {
                tile.position = target
                tile.setScale(scale)
            }
        }
    }

    private func baseTileSize() -> CGSize {
        let available = size.width - (scenePadding * 2) - (tileGap * CGFloat(bankCapacity - 1))
        let width = floor(max(36, min(64, available / CGFloat(bankCapacity))))
        return CGSize(width: width, height: floor(width * 1.1))
    }

    private func rowYPositions() -> [Row: CGFloat] {
        let usableHeight = size.height - (scenePadding * 2)
        let top = scenePadding + usableHeight
        return [
            .word1: top * 0.70,
            .word2: top * 0.56,
            .bank1: top * 0.28,
            .bank2: top * 0.14,
        ]
    }

    private func closestRow(to point: CGPoint) -> Row {
        let rowYs = rowYPositions()
        return Row.allCases.min(by: { abs((rowYs[$0] ?? 0) - point.y) < abs((rowYs[$1] ?? 0) - point.y) }) ?? .bank1
    }

    private func rebalanceBanks() {
        var bank1 = tilesByRow[.bank1] ?? []
        var bank2 = tilesByRow[.bank2] ?? []

        while bank1.count > bankCapacity {
            bank2.append(bank1.removeLast())
        }
        while bank2.count > bankCapacity {
            bank1.append(bank2.removeLast())
        }

        tilesByRow[.bank1] = bank1
        tilesByRow[.bank2] = bank2
    }

    // MARK: - Loading

    private func loadAssetsIfNeeded() {
        guard matchStore == nil || definitions == nil else { return }

        guard
            let matchURL = Bundle.main.url(forResource: "matchdata", withExtension: "packed"),
            let idxURL = Bundle.main.url(forResource: "words", withExtension: "idx"),
            let defURL = Bundle.main.url(forResource: "words", withExtension: "def")
        else {
            return
        }

        do {
            let store = try MatchDataStore(data: try Data(contentsOf: matchURL))
            matchStore = store
            definitions = Definitions(indexData: try Data(contentsOf: idxURL), definitionsData: try Data(contentsOf: defURL))
            nextMatchIndex = initialMatchIndex(matchCount: store.count)
        } catch {
            matchStore = nil
            definitions = nil
        }
    }

    private func initialMatchIndex(matchCount: Int) -> Int {
        guard matchCount > 0 else { return 0 }

        let defaults = UserDefaults.standard
        if let saved = defaults.object(forKey: "nextMatchIndex") as? Int {
            return Swift.max(0, Swift.min(saved, matchCount - 1))
        }

        let scatter: Double
        if let savedScatter = defaults.object(forKey: "nextScatter") as? Double, !savedScatter.isNaN {
            scatter = savedScatter
        } else {
            let generated = Double.random(in: 0..<1)
            defaults.set(generated, forKey: "nextScatter")
            scatter = generated
        }

        let idx = (Int((Double(matchCount) * scatter) + 1) % matchCount)
        defaults.set(idx, forKey: "nextMatchIndex")
        return idx
    }

    private func loadNextMatch() {
        guard let matchStore else { return }
        do {
            let match = try matchStore.match(at: nextMatchIndex)
            nextMatchIndex = (nextMatchIndex + 1) % matchStore.count
            UserDefaults.standard.set(nextMatchIndex, forKey: "nextMatchIndex")
            applyMatch(match)
        } catch {
            // noop for now
        }
    }

    private func applyMatch(_ match: Match) {
        removeAllChildren()
        bestTracker.reset()
        currentScore = 0
        lastWord1Definition = nil
        lastWord2Definition = nil

        tileNodes = match.tiles.map { tile in
            let node = TileNode(tile: tile, size: baseTileSize(), fontName: "IstokWeb-Bold")
            node.zPosition = 1
            return node
        }

        configureLabels()

        for node in tileNodes {
            addChild(node)
        }

        tilesByRow[.word1] = []
        tilesByRow[.word2] = []
        tilesByRow[.bank1] = tileNodes
        tilesByRow[.bank2] = []
        rebalanceBanks()

        layoutAll(animated: false)
    }

    private func currentRackState() -> RackState {
        let indexByNode = Dictionary(uniqueKeysWithValues: tileNodes.enumerated().map { (ObjectIdentifier($0.element), $0.offset) })

        func indices(in row: Row) -> [Int] {
            (tilesByRow[row] ?? []).map { node in
                guard let index = indexByNode[ObjectIdentifier(node)] else {
                    preconditionFailure("Tile node not found in tileNodes")
                }
                return index
            }
        }

        return RackState(
            word1: indices(in: .word1),
            word2: indices(in: .word2),
            bank1: indices(in: .bank1),
            bank2: indices(in: .bank2)
        )
    }

    private func applyRackState(_ state: RackState) {
        tilesByRow[.word1] = state.word1.map { tileNodes[$0] }
        tilesByRow[.word2] = state.word2.map { tileNodes[$0] }
        tilesByRow[.bank1] = state.bank1.map { tileNodes[$0] }
        tilesByRow[.bank2] = state.bank2.map { tileNodes[$0] }
    }

    private func currentWordValidity() -> (isWord1Valid: Bool, isWord2Valid: Bool) {
        guard let definitions else { return (false, false) }

        let word1 = (tilesByRow[.word1] ?? []).map { $0.tile.letter }.joined()
        let word2 = (tilesByRow[.word2] ?? []).map { $0.tile.letter }.joined()

        let isWord1Valid = ((try? definitions.definition(for: word1)) ?? nil) != nil
        let isWord2Valid = ((try? definitions.definition(for: word2)) ?? nil) != nil
        return (isWord1Valid, isWord2Valid)
    }

    private func updateScoreAndDefinitions() {
        let word1Tiles = tilesByRow[.word1] ?? []
        let word2Tiles = tilesByRow[.word2] ?? []

        let word1 = word1Tiles.map { $0.tile.letter }.joined()
        let word2 = word2Tiles.map { $0.tile.letter }.joined()

        var score = 0

        let word1Definition: Definitions.Definition?
        let word2Definition: Definitions.Definition?
        if let defs = definitions {
            word1Definition = (try? defs.definition(for: word1)) ?? nil
            word2Definition = (try? defs.definition(for: word2)) ?? nil
        } else {
            word1Definition = nil
            word2Definition = nil
        }

        let isWord1Valid = word1Definition != nil
        let isWord2Valid = word2Definition != nil
        lastWord1Definition = word1Definition
        lastWord2Definition = word2Definition

        if isWord1Valid {
            score += (try? WordiestScoring.scoreWord(word1Tiles.map(\.tile))) ?? 0
        }
        if isWord2Valid {
            score += (try? WordiestScoring.scoreWord(word2Tiles.map(\.tile))) ?? 0
        }

        currentScore = score
        bestTracker.observe(state: currentRackState(), bestScoreCandidate: score)
        scoreLabel.text = MatchStrings.totalScoreWithBest(score, best: bestTracker.bestScore)

        if let d = word1Definition {
            definition1Label.text = "\(d.partOfSpeech): \(d.definition)"
        } else {
            definition1Label.text = word1.isEmpty ? "" : "Not a word."
        }

        if let d = word2Definition {
            definition2Label.text = "\(d.partOfSpeech): \(d.definition)"
        } else {
            definition2Label.text = word2.isEmpty ? "" : "Not a word."
        }
    }

    private static func overshootTimingFunction() -> @Sendable (Float) -> Float {
        // Android's OvershootInterpolator-like curve ("easeOutBack").
        { t in
            let s: Float = 1.70158
            let p = t - 1
            return p * p * ((s + 1) * p + s) + 1
        }
    }
}
