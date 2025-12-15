import SpriteKit
import UIKit
import WordiestCore

final class TileNode: SKNode {
    let tile: Tile
    let baseSize: CGSize

    private let bonusStroke: SKShapeNode?
    private let bonusFill: SKShapeNode?
    private let tileStroke: SKShapeNode
    private let tileFill: SKShapeNode
    private let letterLabel: SKLabelNode
    private let valueNode: SKSpriteNode?
    private let bonusNodeTop: SKSpriteNode?
    private let bonusNodeBottom: SKSpriteNode?
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

        let smallFontSize = size.width * WordiestTileStyle.smallFontRatio
        let smallUIFont = UIFont(name: fontName ?? "", size: smallFontSize) ?? .systemFont(ofSize: smallFontSize, weight: .bold)
        let scale = UIScreen.main.scale

        if tile.value > 0 {
            let node = Self.glyphSprite(text: String(tile.value), font: smallUIFont, scale: scale)
            node.zPosition = 10
            self.valueNode = node
        } else {
            self.valueNode = nil
        }

        let bonus = tile.bonus?.uppercased()
        if let bonus, !bonus.isEmpty {
            let top = Self.glyphSprite(text: bonus, font: smallUIFont, scale: scale)
            let bottom = Self.glyphSprite(text: bonus, font: smallUIFont, scale: scale)
            top.zPosition = 10
            bottom.zPosition = 10
            self.bonusNodeTop = top
            self.bonusNodeBottom = bottom
        } else {
            self.bonusNodeTop = nil
            self.bonusNodeBottom = nil
        }

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

        let edgePadding = size.width * WordiestTileStyle.padding3dpRatio
        let valuePadding = size.width * WordiestTileStyle.padding6dpRatio

        if let valueNode {
            valueNode.position = CGPoint(
                x: (size.width / 2.0) - valuePadding - (valueNode.size.width / 2.0),
                y: (-size.height / 2.0) + tileOffsetY + valuePadding + (valueNode.size.height / 2.0)
            )
            addChild(valueNode)
        }

        if let bonusNodeTop, let bonusNodeBottom {
            bonusNodeTop.position = CGPoint(
                x: 0,
                y: (size.height / 2.0) - edgePadding - (bonusNodeTop.size.height / 2.0)
            )
            bonusNodeBottom.position = CGPoint(
                x: 0,
                y: (-size.height / 2.0) + edgePadding + (bonusNodeBottom.size.height / 2.0)
            )
            addChild(bonusNodeTop)
            addChild(bonusNodeBottom)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func glyphSprite(text: String, font: UIFont, scale: CGFloat) -> SKSpriteNode {
        let image = GlyphBoundsText.image(text: text, font: font, scale: scale)
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let node = SKSpriteNode(texture: texture)
        node.colorBlendFactor = 1
        node.color = .white
        return node
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
        valueNode?.color = foreground
        bonusNodeTop?.color = foreground
        bonusNodeBottom?.color = foreground
    }
}
