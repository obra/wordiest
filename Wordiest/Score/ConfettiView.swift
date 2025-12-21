import SwiftUI
import UIKit
import WordiestCore

struct ConfettiView: UIViewRepresentable {
    var tiles: [Tile]

    func makeUIView(context: Context) -> TileConfettiEmitterView {
        TileConfettiEmitterView(tiles: tiles)
    }

    func updateUIView(_ uiView: TileConfettiEmitterView, context: Context) {
        uiView.updateTilesIfNeeded(tiles: tiles)
    }
}

final class TileConfettiEmitterView: UIView {
    private var tiles: [Tile]

    override class var layerClass: AnyClass {
        CAEmitterLayer.self
    }

    private var emitterLayer: CAEmitterLayer {
        // swiftlint:disable:next force_cast
        layer as! CAEmitterLayer
    }

    init(tiles: [Tile]) {
        self.tiles = tiles
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep the emitter attached to the bottom, even while bounds are changing.
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY + 10)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
    }

    func updateTilesIfNeeded(tiles: [Tile]) {
        if self.tiles == tiles { return }
        self.tiles = tiles
        emitterLayer.emitterCells = Self.cells(tiles: tiles)
    }

    private func configure() {
        let emitter = emitterLayer
        emitter.emitterShape = .line
        emitter.emitterMode = .outline
        emitter.renderMode = .oldestFirst
        emitter.birthRate = 1.0
        emitter.emitterCells = Self.cells(tiles: tiles)
    }

    private static func cells(tiles: [Tile]) -> [CAEmitterCell] {
        let scale = UIScreen.main.scale
        let imageWidth: CGFloat = 84
        let imageSize = CGSize(width: imageWidth, height: imageWidth * WordiestTileStyle.aspectRatio)
        let tileFill = ColorPalette.palette(index: 1).uiBackground
        let tileInk = ColorPalette.palette(index: 1).uiForeground

        // If there are too few tiles, repeat them so the effect has enough variety.
        var pool = tiles
        if pool.isEmpty {
            pool = [Tile(letter: "W", value: 4, bonus: "4W")]
        }
        while pool.count < 18 {
            pool.append(contentsOf: tiles)
            if pool.count > 40 { break }
        }

        return pool.map { tile in
            let cell = CAEmitterCell()

            cell.birthRate = 1.2
            cell.lifetime = 4.8
            cell.lifetimeRange = 0.8

            cell.velocity = 520
            cell.velocityRange = 180
            cell.yAcceleration = 820
            cell.xAcceleration = 0

            // Fountain upward, with a little spray.
            cell.emissionLongitude = -.pi / 2
            cell.emissionRange = .pi / 7

            cell.spin = 2.4
            cell.spinRange = 3.2

            cell.scale = 0.22
            cell.scaleRange = 0.08
            cell.alphaSpeed = -0.12

            let image = WordiestTileRenderer.image(tile: tile, size: imageSize, background: tileFill, foreground: tileInk, stroke: tileInk, scale: scale)
            cell.contents = image.cgImage
            return cell
        }
    }
}
