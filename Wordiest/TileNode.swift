import SpriteKit
import WordiestCore

final class TileNode: SKNode {
    let tile: Tile

    private let background: SKShapeNode
    private let letterLabel: SKLabelNode
    private let valueLabel: SKLabelNode
    private let bonusLabelTop: SKLabelNode
    private let bonusLabelBottom: SKLabelNode
    private var validStrokeColor: SKColor = .white
    private var invalidStrokeColor: SKColor = .gray

    init(tile: Tile, size: CGSize, fontName: String?) {
        self.tile = tile

        let rect = CGRect(origin: CGPoint(x: -size.width / 2.0, y: -size.height / 2.0), size: size)
        self.background = SKShapeNode(rect: rect, cornerRadius: min(size.width, size.height) * 0.12)
        self.background.lineWidth = max(1, size.width * 0.06)
        self.background.strokeColor = .white
        self.background.fillColor = .black
        self.background.isAntialiased = true

        self.letterLabel = SKLabelNode(fontNamed: fontName)
        self.letterLabel.fontColor = .white
        self.letterLabel.verticalAlignmentMode = .center
        self.letterLabel.horizontalAlignmentMode = .center
        self.letterLabel.fontSize = size.width * 0.55
        self.letterLabel.text = tile.letter.uppercased()

        self.valueLabel = SKLabelNode(fontNamed: fontName)
        self.valueLabel.fontColor = .white
        self.valueLabel.verticalAlignmentMode = .bottom
        self.valueLabel.horizontalAlignmentMode = .right
        self.valueLabel.fontSize = size.width * 0.22
        self.valueLabel.text = tile.value > 0 ? String(tile.value) : nil

        self.bonusLabelTop = SKLabelNode(fontNamed: fontName)
        self.bonusLabelTop.fontColor = .white
        self.bonusLabelTop.verticalAlignmentMode = .top
        self.bonusLabelTop.horizontalAlignmentMode = .center
        self.bonusLabelTop.fontSize = size.width * 0.22

        self.bonusLabelBottom = SKLabelNode(fontNamed: fontName)
        self.bonusLabelBottom.fontColor = .white
        self.bonusLabelBottom.verticalAlignmentMode = .bottom
        self.bonusLabelBottom.horizontalAlignmentMode = .center
        self.bonusLabelBottom.fontSize = size.width * 0.22

        super.init()

        isUserInteractionEnabled = false

        addChild(background)

        letterLabel.position = .zero
        addChild(letterLabel)

        valueLabel.position = CGPoint(x: (size.width / 2.0) - (size.width * 0.10), y: (-size.height / 2.0) + (size.height * 0.06))
        addChild(valueLabel)

        let bonus = tile.bonus?.uppercased()
        bonusLabelTop.text = bonus
        bonusLabelBottom.text = bonus

        if bonus != nil {
            bonusLabelTop.position = CGPoint(x: 0, y: (size.height / 2.0) - (size.height * 0.06))
            bonusLabelBottom.position = CGPoint(x: 0, y: (-size.height / 2.0) + (size.height * 0.06))
            addChild(bonusLabelTop)
            addChild(bonusLabelBottom)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStyle(isValidWordTile: Bool) {
        background.strokeColor = isValidWordTile ? validStrokeColor : invalidStrokeColor
    }

    func applyPalette(background: SKColor, foreground: SKColor, faded: SKColor) {
        validStrokeColor = foreground
        invalidStrokeColor = faded

        self.background.fillColor = background
        self.background.strokeColor = validStrokeColor

        letterLabel.fontColor = foreground
        valueLabel.fontColor = foreground
        bonusLabelTop.fontColor = foreground
        bonusLabelBottom.fontColor = foreground
    }
}
