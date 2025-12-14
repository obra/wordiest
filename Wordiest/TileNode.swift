import SpriteKit
import WordiestCore

final class TileNode: SKNode {
    let tile: Tile
    let baseSize: CGSize

    private let bonusBackground: SKShapeNode?
    private let tileBackground: SKShapeNode
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
        self.tileBackground = SKShapeNode(rect: mainRect, cornerRadius: cornerRadius)
        self.tileBackground.lineWidth = borderWidth
        self.tileBackground.strokeColor = .white
        self.tileBackground.fillColor = .black
        self.tileBackground.isAntialiased = true

        if let bonus = tile.bonus, !bonus.isEmpty {
            let bonusInsetX = size.width * WordiestTileStyle.bonusInsetXRatio
            let bonusRect = CGRect(
                x: (-size.width / 2.0) + bonusInsetX,
                y: -size.height / 2.0,
                width: size.width - (bonusInsetX * 2),
                height: size.height
            )
            let bonusBackground = SKShapeNode(rect: bonusRect, cornerRadius: cornerRadius)
            bonusBackground.lineWidth = borderWidth
            bonusBackground.strokeColor = .white
            bonusBackground.fillColor = .black
            bonusBackground.isAntialiased = true
            self.bonusBackground = bonusBackground
        } else {
            self.bonusBackground = nil
        }

        self.letterLabel = SKLabelNode(fontNamed: fontName)
        self.letterLabel.fontColor = .white
        self.letterLabel.verticalAlignmentMode = .center
        self.letterLabel.horizontalAlignmentMode = .center
        self.letterLabel.fontSize = size.width * WordiestTileStyle.letterFontRatio
        self.letterLabel.text = tile.letter.uppercased()

        self.valueLabel = SKLabelNode(fontNamed: fontName)
        self.valueLabel.fontColor = .white
        self.valueLabel.verticalAlignmentMode = .baseline
        self.valueLabel.horizontalAlignmentMode = .right
        self.valueLabel.fontSize = size.width * WordiestTileStyle.smallFontRatio
        self.valueLabel.text = tile.value > 0 ? String(tile.value) : nil

        self.bonusLabelTop = SKLabelNode(fontNamed: fontName)
        self.bonusLabelTop.fontColor = .white
        self.bonusLabelTop.verticalAlignmentMode = .baseline
        self.bonusLabelTop.horizontalAlignmentMode = .center
        self.bonusLabelTop.fontSize = size.width * WordiestTileStyle.smallFontRatio

        self.bonusLabelBottom = SKLabelNode(fontNamed: fontName)
        self.bonusLabelBottom.fontColor = .white
        self.bonusLabelBottom.verticalAlignmentMode = .baseline
        self.bonusLabelBottom.horizontalAlignmentMode = .center
        self.bonusLabelBottom.fontSize = size.width * WordiestTileStyle.smallFontRatio

        super.init()

        isUserInteractionEnabled = false

        if let bonusBackground {
            addChild(bonusBackground)
        }
        addChild(tileBackground)

        letterLabel.position = .zero
        addChild(letterLabel)

        valueLabel.position = CGPoint(
            x: (size.width / 2.0) - (size.width * WordiestTileStyle.padding7dpRatio),
            y: (-size.height / 2.0) + (size.height * WordiestTileStyle.valueBaselineFromBottomRatio)
        )
        addChild(valueLabel)

        let bonus = tile.bonus?.uppercased()
        bonusLabelTop.text = bonus
        bonusLabelBottom.text = bonus

        if let bonus, !bonus.isEmpty {
            bonusLabelTop.position = CGPoint(x: 0, y: (size.height / 2.0) - (size.height * WordiestTileStyle.bonusTopBaselineFromTopRatio))
            bonusLabelBottom.position = CGPoint(x: 0, y: (-size.height / 2.0) + (size.height * WordiestTileStyle.bonusBottomBaselineFromBottomRatio))
            addChild(bonusLabelTop)
            addChild(bonusLabelBottom)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStyle(isValidWordTile: Bool) {
        let stroke = isValidWordTile ? validStrokeColor : invalidStrokeColor
        tileBackground.strokeColor = stroke
        bonusBackground?.strokeColor = stroke
    }

    func applyPalette(background: SKColor, foreground: SKColor, faded: SKColor) {
        validStrokeColor = foreground
        invalidStrokeColor = faded

        tileBackground.fillColor = background
        tileBackground.strokeColor = validStrokeColor
        bonusBackground?.fillColor = background
        bonusBackground?.strokeColor = validStrokeColor

        letterLabel.fontColor = foreground
        valueLabel.fontColor = foreground
        bonusLabelTop.fontColor = foreground
        bonusLabelBottom.fontColor = foreground
    }
}
