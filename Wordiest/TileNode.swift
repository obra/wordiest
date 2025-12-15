import SpriteKit
import UIKit
import WordiestCore

final class TileNode: SKNode {
    let tile: Tile
    let baseSize: CGSize

    private let sprite: SKSpriteNode
    private var backgroundColor: UIColor = .black
    private var foregroundColor: UIColor = .white
    private var fadedColor: UIColor = .gray
    private var strokeColor: UIColor = .white

    init(tile: Tile, size: CGSize, fontName: String?) {
        self.tile = tile
        self.baseSize = size

        let initialTexture = SKTexture(image: UIImage())
        initialTexture.filteringMode = .linear
        self.sprite = SKSpriteNode(texture: initialTexture, size: size)
        self.sprite.zPosition = 10

        super.init()

        isUserInteractionEnabled = false
        addChild(sprite)
        updateTexture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStyle(isValidWordTile: Bool) {
        strokeColor = isValidWordTile ? foregroundColor : fadedColor
        updateTexture()
    }

    func applyPalette(background: SKColor, foreground: SKColor, faded: SKColor) {
        backgroundColor = UIColor(cgColor: background.cgColor)
        foregroundColor = UIColor(cgColor: foreground.cgColor)
        fadedColor = UIColor(cgColor: faded.cgColor)
        strokeColor = foregroundColor
        updateTexture()
    }

    private func updateTexture() {
        let scale = UIScreen.main.scale
        let image = WordiestTileRenderer.image(
            tile: tile,
            size: baseSize,
            background: backgroundColor,
            foreground: foregroundColor,
            stroke: strokeColor,
            scale: scale
        )
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        sprite.texture = texture
        sprite.size = baseSize
    }
}
