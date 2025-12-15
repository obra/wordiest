import SpriteKit
import WordiestCore

final class TileNode: SKNode {
    let tile: Tile
    let baseSize: CGSize

    private let bonusStroke: SKShapeNode?
    private let bonusFill: SKShapeNode?
    private let tileStroke: SKShapeNode
    private let tileFill: SKShapeNode
    private let letterLabel: SKLabelNode
    private let valueLabel: SKLabelNode
    private let bonusLabelTop: SKLabelNode
    private let bonusLabelBottom: SKLabelNode
    private var validStrokeColor: SKColor = .white
    private var invalidStrokeColor: SKColor = .gray

    init(tile: Tile, size: CGSize, fontName: String?) {
        self.tile = tile
        self.baseSize = size

        let cornerRadius = size.width * WordiestTileStyle.cornerRadiusRatio
        let borderWidth = max(1, size.width * WordiestTileStyle.borderWidthRatio)
        let tileOffsetY = size.height * WordiestTileStyle.tileOffsetYRatio

        let mainRect = CGRect(
            x: -size.width / 2.0,
            y: (-size.height / 2.0) + tileOffsetY,
            width: size.width,
            height: size.height - (tileOffsetY * 2)
        )
        self.tileStroke = SKShapeNode(rect: mainRect, cornerRadius: cornerRadius)
        self.tileStroke.lineWidth = borderWidth
        self.tileStroke.strokeColor = .white
        self.tileStroke.fillColor = .clear
        self.tileStroke.isAntialiased = true

        self.tileFill = SKShapeNode(rect: mainRect, cornerRadius: cornerRadius)
        self.tileFill.lineWidth = 0
        self.tileFill.strokeColor = .clear
        self.tileFill.fillColor = .black
        self.tileFill.isAntialiased = true

        if let bonus = tile.bonus, !bonus.isEmpty {
            let bonusInsetX = size.width * WordiestTileStyle.bonusInsetXRatio
            let bonusRect = CGRect(
                x: (-size.width / 2.0) + bonusInsetX,
                y: -size.height / 2.0,
                width: size.width - (bonusInsetX * 2),
                height: size.height
            )
            let bonusStroke = SKShapeNode(rect: bonusRect, cornerRadius: cornerRadius)
            bonusStroke.lineWidth = borderWidth
            bonusStroke.strokeColor = .white
            bonusStroke.fillColor = .clear
            bonusStroke.isAntialiased = true
            self.bonusStroke = bonusStroke

            let bonusFill = SKShapeNode(rect: bonusRect, cornerRadius: cornerRadius)
            bonusFill.lineWidth = 0
            bonusFill.strokeColor = .clear
            bonusFill.fillColor = .black
            bonusFill.isAntialiased = true
            self.bonusFill = bonusFill
        } else {
            self.bonusStroke = nil
            self.bonusFill = nil
        }

        self.letterLabel = SKLabelNode(fontNamed: fontName)
        self.letterLabel.fontColor = .white
        self.letterLabel.verticalAlignmentMode = .center
        self.letterLabel.horizontalAlignmentMode = .center
        self.letterLabel.fontSize = size.width * WordiestTileStyle.letterFontRatio
        self.letterLabel.text = tile.letter.uppercased()
        self.letterLabel.zPosition = 10

        self.valueLabel = SKLabelNode(fontNamed: fontName)
        self.valueLabel.fontColor = .white
        self.valueLabel.verticalAlignmentMode = .bottom
        self.valueLabel.horizontalAlignmentMode = .right
        self.valueLabel.fontSize = size.width * WordiestTileStyle.smallFontRatio
        self.valueLabel.text = tile.value > 0 ? String(tile.value) : nil
        self.valueLabel.zPosition = 10

        self.bonusLabelTop = SKLabelNode(fontNamed: fontName)
        self.bonusLabelTop.fontColor = .white
        self.bonusLabelTop.verticalAlignmentMode = .top
        self.bonusLabelTop.horizontalAlignmentMode = .center
        self.bonusLabelTop.fontSize = size.width * WordiestTileStyle.smallFontRatio
        self.bonusLabelTop.zPosition = 10

        self.bonusLabelBottom = SKLabelNode(fontNamed: fontName)
        self.bonusLabelBottom.fontColor = .white
        self.bonusLabelBottom.verticalAlignmentMode = .bottom
        self.bonusLabelBottom.horizontalAlignmentMode = .center
        self.bonusLabelBottom.fontSize = size.width * WordiestTileStyle.smallFontRatio
        self.bonusLabelBottom.zPosition = 10

        super.init()

        isUserInteractionEnabled = false

        if let bonusStroke {
            bonusStroke.zPosition = 0
            addChild(bonusStroke)
        }
        tileStroke.zPosition = 1
        addChild(tileStroke)
        if let bonusFill {
            bonusFill.zPosition = 2
            addChild(bonusFill)
        }
        tileFill.zPosition = 3
        addChild(tileFill)

        letterLabel.position = .zero
        addChild(letterLabel)

        valueLabel.position = CGPoint(
            x: (size.width / 2.0) - (size.width * WordiestTileStyle.padding3dpRatio),
            y: (-size.height / 2.0) + tileOffsetY + (size.width * WordiestTileStyle.padding3dpRatio)
        )
        addChild(valueLabel)

        let bonus = tile.bonus?.uppercased()
        bonusLabelTop.text = bonus
        bonusLabelBottom.text = bonus

        if let bonus, !bonus.isEmpty {
            bonusLabelTop.position = CGPoint(x: 0, y: (size.height / 2.0) - (size.width * WordiestTileStyle.padding3dpRatio))
            bonusLabelBottom.position = CGPoint(x: 0, y: (-size.height / 2.0) + (size.width * WordiestTileStyle.padding3dpRatio))
            addChild(bonusLabelTop)
            addChild(bonusLabelBottom)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStyle(isValidWordTile: Bool) {
        let stroke = isValidWordTile ? validStrokeColor : invalidStrokeColor
        tileStroke.strokeColor = stroke
        bonusStroke?.strokeColor = stroke
    }

    func applyPalette(background: SKColor, foreground: SKColor, faded: SKColor) {
        validStrokeColor = foreground
        invalidStrokeColor = faded

        tileFill.fillColor = background
        tileStroke.strokeColor = validStrokeColor
        bonusFill?.fillColor = background
        bonusStroke?.strokeColor = validStrokeColor

        letterLabel.fontColor = foreground
        valueLabel.fontColor = foreground
        bonusLabelTop.fontColor = foreground
        bonusLabelBottom.fontColor = foreground
    }
}
