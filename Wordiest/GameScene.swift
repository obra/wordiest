import SpriteKit
import WordiestCore
import UIKit

@MainActor
final class GameScene: SKScene {
    private enum Row: CaseIterable {
        case word1
        case word2
        case bank1
        case bank2
    }

    private let tileGap: CGFloat = 3
    private let appSpacer: CGFloat = 6
    private let baselineInset: CGFloat = 12
    private let bankCapacity = 7

    private var matchStore: MatchDataStore?
    private var definitions: Definitions?
    private var nextMatchIndex = 0
    private(set) var currentMatchIndex: Int?
    private(set) var currentMatch: Match?

    private var tileNodes: [TileNode] = []
    private var tilesByRow: [Row: [TileNode]] = [:]
    private var lastRowCenters: [Row: CGFloat] = [:]

    private var dragging: (node: TileNode, offset: CGPoint, baseScale: CGFloat)?
    private let bestTracker = BestTracker()
    private var currentScore: Int = 0

    private let scoreLabel = SKLabelNode(fontNamed: "IstokWeb-Bold")
    private let definition1Label = SKLabelNode(fontNamed: "IstokWeb-Bold")
    private let definition2Label = SKLabelNode(fontNamed: "IstokWeb-Bold")

    private let baseline1 = SKShapeNode()
    private let baseline2 = SKShapeNode()

    var onRequestOpenWiktionary: ((String) -> Void)?
    var safeAreaInsetsOverride: UIEdgeInsets? {
        didSet {
            layoutAll(animated: false)
        }
    }

    private var lastWord1Definition: Definitions.Definition?
    private var lastWord2Definition: Definitions.Definition?

    var isReview: Bool = false {
        didSet {
            layoutAll(animated: false)
        }
    }
    var soundEnabled: Bool = true
    private var palette: (background: SKColor, foreground: SKColor, faded: SKColor) = (.black, .white, .gray)

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
        configure(size: view.bounds.size)
        backgroundColor = palette.background

        if tilesByRow.isEmpty {
            for row in Row.allCases {
                tilesByRow[row] = []
            }
        }

        configureLabels()
        if matchStore != nil, definitions != nil {
            loadNextMatch()
        }
    }

    func applyPalette(_ palette: ColorPalette) {
        self.palette = (palette.uiBackground, palette.uiForeground, palette.uiFaded)
        backgroundColor = self.palette.background

        scoreLabel.fontColor = self.palette.foreground
        definition1Label.fontColor = self.palette.foreground
        definition2Label.fontColor = self.palette.foreground

        for node in tileNodes {
            node.applyPalette(background: self.palette.background, foreground: self.palette.foreground, faded: self.palette.faded)
        }
        updateScoreAndDefinitions()
    }

    func setAssets(matchStore: MatchDataStore, definitions: Definitions) {
        let shouldReload = self.matchStore == nil || self.definitions == nil
        self.matchStore = matchStore
        self.definitions = definitions
        if shouldReload {
            nextMatchIndex = initialMatchIndex(matchCount: matchStore.count)
            loadNextMatch()
        }
    }

    func shuffle() {
        let state = currentRackState()
        applyRackState(Shuffle.shuffled(state: state))
        rebalanceBanks()
        layoutAll(animated: true)
        if soundEnabled {
            run(SKAction.playSoundFileNamed("pickup.mp3", waitForCompletion: false))
        }
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
        if soundEnabled {
            run(SKAction.playSoundFileNamed("pickup.mp3", waitForCompletion: false))
        }
    }

    func submit() {
        if isReview { return }
        loadNextMatch()
        if soundEnabled {
            run(SKAction.playSoundFileNamed("drop.mp3", waitForCompletion: false))
        }
    }

    func advanceToNextMatch() {
        loadNextMatch()
    }

    func loadReviewMatch(matchIndex: Int, match: Match, wordsEncoding: UInt64) {
        isReview = true
        currentMatchIndex = matchIndex
        currentMatch = match

        let initialState = ReviewPlacement.rackState(tileCount: match.tiles.count, encoding: wordsEncoding)
        applyMatch(match, initialRackState: initialState)
    }

    func currentWordsEncoding() -> UInt64? {
        let state = currentRackState()
        return try? SubsetEncoding.encode(word1: state.word1, word2: state.word2)
    }

    func currentScoreValue() -> Int {
        currentScore
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

    var hasInProgressMove: Bool {
        !(tilesByRow[.word1] ?? []).isEmpty || !(tilesByRow[.word2] ?? []).isEmpty
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
        if soundEnabled {
            run(SKAction.playSoundFileNamed("pickup.mp3", waitForCompletion: false))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging else { return }
        let point = touch.location(in: self)
        dragging.node.position = CGPoint(x: point.x - dragging.offset.x, y: point.y - dragging.offset.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging else { return }
        let point = touch.location(in: self)
        let dropX = DragMath.draggedCenterX(touchX: point.x, touchOffsetX: dragging.offset.x)
        drop(dragging.node, dropX: dropX, at: point)
        self.dragging = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging else { return }
        let point = touch.location(in: self)
        let dropX = DragMath.draggedCenterX(touchX: point.x, touchOffsetX: dragging.offset.x)
        drop(dragging.node, dropX: dropX, at: point)
        self.dragging = nil
    }

    private func drop(_ node: TileNode, dropX: CGFloat, at point: CGPoint) {
        let row = closestRow(to: point)
        let (leftX, contentWidth, _) = contentLayout()
        let baseTileSize = baseTileSize(availableWidth: contentWidth)
        let existing = tilesByRow[row] ?? []
        let scaleCount = row == .bank1 || row == .bank2 ? bankCapacity : (existing.count + 1)
        let metrics = TileRowLayout.metrics(
            baseTileSize: baseTileSize,
            baseGap: tileGap,
            layoutCount: existing.count + 1,
            scaleCount: scaleCount,
            availableWidth: contentWidth,
            leftX: leftX
        )
        tilesByRow[row] = TileRowLayout.insert(element: node, into: existing, dropX: dropX, metrics: metrics)

        if row == .bank1 || row == .bank2 {
            rebalanceBanks()
        }

        node.zPosition = 1
        layoutAll(animated: true)
        if soundEnabled {
            run(SKAction.playSoundFileNamed("drop.mp3", waitForCompletion: false))
        }
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
        scoreLabel.fontColor = palette.foreground
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = 20
        if scoreLabel.parent == nil { addChild(scoreLabel) }

        for baseline in [baseline1, baseline2] {
            baseline.strokeColor = .clear
            baseline.fillColor = palette.faded
            baseline.alpha = 0.35
            baseline.zPosition = 0
            if baseline.parent == nil { addChild(baseline) }
        }

        for label in [definition1Label, definition2Label] {
            label.fontSize = 14
            label.fontColor = palette.foreground
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .top
            label.zPosition = 20
            label.numberOfLines = 3
            label.preferredMaxLayoutWidth = max(200, size.width - (appSpacer * 2))
            if label.parent == nil { addChild(label) }
        }
    }

    private func contentLayout() -> (leftX: CGFloat, contentWidth: CGFloat, safeInsets: UIEdgeInsets) {
        var insets = safeAreaInsetsOverride ?? view?.safeAreaInsets ?? .zero
        if isReview {
            insets.top += 50
        }
        let width = max(0, size.width - (appSpacer * 2) - insets.left - insets.right)
        let leftX = appSpacer + insets.left
        return (leftX, width, insets)
    }

    private func layoutAll(animated: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        let (leftX, contentWidth, insets) = contentLayout()

        definition1Label.preferredMaxLayoutWidth = max(200, contentWidth)
        definition2Label.preferredMaxLayoutWidth = max(200, contentWidth)

        updateScoreAndDefinitions()

        let scoreY = size.height - appSpacer - insets.top
        scoreLabel.position = CGPoint(x: leftX + (contentWidth / 2), y: scoreY)

        let baseTileSize = baseTileSize(availableWidth: contentWidth)

        func tileMetrics(row: Row, tileCount: Int) -> TileRowLayout.Metrics {
            let layoutCount = max(tileCount, 1)
            let scaleCount = (row == .bank1 || row == .bank2) ? bankCapacity : layoutCount
            return TileRowLayout.metrics(
                baseTileSize: baseTileSize,
                baseGap: tileGap,
                layoutCount: layoutCount,
                scaleCount: scaleCount,
                availableWidth: contentWidth,
                leftX: leftX
            )
        }

        let word1Count = tilesByRow[.word1]?.count ?? 0
        let word2Count = tilesByRow[.word2]?.count ?? 0
        let bank1Count = tilesByRow[.bank1]?.count ?? 0
        let bank2Count = tilesByRow[.bank2]?.count ?? 0

        let word1TileMetrics = tileMetrics(row: .word1, tileCount: word1Count)
        let word2TileMetrics = tileMetrics(row: .word2, tileCount: word2Count)
        let bank1TileMetrics = tileMetrics(row: .bank1, tileCount: bank1Count)
        let bank2TileMetrics = tileMetrics(row: .bank2, tileCount: bank2Count)

        let scoreLabelHeight = max(scoreLabel.frame.height, scoreLabel.fontSize)
        let scoreAreaHeight = appSpacer + scoreLabelHeight

        let word1ExtraBelow = ((definition1Label.text ?? "").isEmpty ? 0 : (tileGap + definition1Label.frame.height))
        let word2ExtraBelow = ((definition2Label.text ?? "").isEmpty ? 0 : (tileGap + definition2Label.frame.height))

        let centers = MatchVerticalLayout.centers(
            containerHeight: size.height,
            topInset: appSpacer + insets.top,
            bottomInset: appSpacer + insets.bottom,
            spacer: appSpacer,
            scoreAreaHeight: scoreAreaHeight,
            word1Height: word1TileMetrics.tileSize.height + word1ExtraBelow,
            word2Height: word2TileMetrics.tileSize.height + word2ExtraBelow,
            bank1Height: bank1TileMetrics.tileSize.height,
            bank2Height: bank2TileMetrics.tileSize.height
        )

        let rowYs: [Row: CGFloat] = [
            .word1: centers.word1 + (word1ExtraBelow / 2.0),
            .word2: centers.word2 + (word2ExtraBelow / 2.0),
            .bank1: centers.bank1,
            .bank2: centers.bank2,
        ]
        lastRowCenters = rowYs

        for row in Row.allCases {
            let tiles = tilesByRow[row] ?? []
            layoutRow(tiles, row: row, atY: rowYs[row] ?? 0, baseTileSize: baseTileSize, leftX: leftX, contentWidth: contentWidth, animated: animated)
        }

        layoutBaselines(
            rowYs: rowYs,
            word1TileHeight: word1TileMetrics.tileSize.height,
            word2TileHeight: word2TileMetrics.tileSize.height,
            leftX: leftX,
            contentWidth: contentWidth
        )

        definition1Label.position = CGPoint(
            x: leftX + (contentWidth / 2),
            y: (rowYs[.word1] ?? 0) - (word1TileMetrics.tileSize.height / 2.0) - tileGap
        )
        definition2Label.position = CGPoint(
            x: leftX + (contentWidth / 2),
            y: (rowYs[.word2] ?? 0) - (word2TileMetrics.tileSize.height / 2.0) - tileGap
        )
    }

    private func layoutBaselines(rowYs: [Row: CGFloat], word1TileHeight: CGFloat, word2TileHeight: CGFloat, leftX: CGFloat, contentWidth: CGFloat) {
        let baselineHeight1 = max(3, word1TileHeight * 0.06)
        let baselineHeight2 = max(3, word2TileHeight * 0.06)
        let inset = max(0, baselineInset - appSpacer)
        let baselineLeftX = leftX + inset
        let baselineWidth = max(0, contentWidth - (inset * 2))
        let rect1 = CGRect(x: baselineLeftX, y: (rowYs[.word1] ?? 0) - (word1TileHeight / 2) - baselineHeight1 - 2, width: baselineWidth, height: baselineHeight1)
        let rect2 = CGRect(x: baselineLeftX, y: (rowYs[.word2] ?? 0) - (word2TileHeight / 2) - baselineHeight2 - 2, width: baselineWidth, height: baselineHeight2)

        baseline1.path = CGPath(rect: rect1, transform: nil)
        baseline2.path = CGPath(rect: rect2, transform: nil)
        baseline1.fillColor = palette.faded
        baseline2.fillColor = palette.faded
    }

    private func layoutRow(_ tiles: [TileNode], row: Row, atY y: CGFloat, baseTileSize: CGSize, leftX: CGFloat, contentWidth: CGFloat, animated: Bool) {
        let layoutCount = max(tiles.count, 1)
        let scaleCount = (row == .bank1 || row == .bank2) ? bankCapacity : layoutCount
        let metrics = TileRowLayout.metrics(baseTileSize: baseTileSize, baseGap: tileGap, layoutCount: layoutCount, scaleCount: scaleCount, availableWidth: contentWidth, leftX: leftX)
        let scale = baseTileSize.width > 0 ? metrics.tileSize.width / baseTileSize.width : 1
        let step = metrics.tileSize.width + metrics.gap

        for (idx, tile) in tiles.enumerated() {
            let target = CGPoint(x: metrics.startX + (CGFloat(idx) * step), y: y)

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

    private func baseTileSize(availableWidth: CGFloat) -> CGSize {
        let available = availableWidth - (tileGap * CGFloat(bankCapacity - 1))
        let width = floor(max(36, min(64, available / CGFloat(bankCapacity))))
        return CGSize(width: width, height: floor(width * 1.1))
    }

    private func closestRow(to point: CGPoint) -> Row {
        return Row.allCases.min(by: { abs((lastRowCenters[$0] ?? 0) - point.y) < abs((lastRowCenters[$1] ?? 0) - point.y) }) ?? .bank1
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
            currentMatchIndex = nextMatchIndex
            let match = try matchStore.match(at: nextMatchIndex)
            currentMatch = match
            nextMatchIndex = (nextMatchIndex + 1) % matchStore.count
            UserDefaults.standard.set(nextMatchIndex, forKey: "nextMatchIndex")
            applyMatch(match, initialRackState: nil)
        } catch {
            // noop for now
        }
    }

    private func applyMatch(_ match: Match, initialRackState: RackState?) {
        removeAllChildren()
        bestTracker.reset()
        currentScore = 0
        lastWord1Definition = nil
        lastWord2Definition = nil

        let (_, contentWidth, _) = contentLayout()
        let tileSize = baseTileSize(availableWidth: contentWidth)

        tileNodes = match.tiles.map { tile in
            let node = TileNode(tile: tile, size: tileSize, fontName: "IstokWeb-Bold")
            node.applyPalette(background: palette.background, foreground: palette.foreground, faded: palette.faded)
            node.zPosition = 1
            return node
        }

        configureLabels()

        for node in tileNodes {
            addChild(node)
        }

        if let initialRackState {
            applyRackState(initialRackState)
        } else {
            tilesByRow[.word1] = []
            tilesByRow[.word2] = []
            tilesByRow[.bank1] = tileNodes
            tilesByRow[.bank2] = []
        }
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
        var word1Points = 0
        var word2Points = 0

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

        for node in tilesByRow[.word1] ?? [] { node.setStyle(isValidWordTile: isWord1Valid) }
        for node in tilesByRow[.word2] ?? [] { node.setStyle(isValidWordTile: isWord2Valid) }
        for node in tilesByRow[.bank1] ?? [] { node.setStyle(isValidWordTile: true) }
        for node in tilesByRow[.bank2] ?? [] { node.setStyle(isValidWordTile: true) }

        if isWord1Valid {
            word1Points = (try? WordiestScoring.scoreWord(word1Tiles.map(\.tile))) ?? 0
            score += word1Points
        }
        if isWord2Valid {
            word2Points = (try? WordiestScoring.scoreWord(word2Tiles.map(\.tile))) ?? 0
            score += word2Points
        }

        currentScore = score
        bestTracker.observe(state: currentRackState(), bestScoreCandidate: score)
        scoreLabel.text = MatchStrings.totalScoreWithBest(score, best: bestTracker.bestScore)

        if let d = word1Definition {
            definition1Label.text = MatchStrings.definitionText(word: word1, points: word1Points, seeWord: d.seeWord, definition: d.definition)
        } else {
            definition1Label.text = word1.isEmpty ? "" : "Not a word."
        }

        if let d = word2Definition {
            definition2Label.text = MatchStrings.definitionText(word: word2, points: word2Points, seeWord: d.seeWord, definition: d.definition)
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
