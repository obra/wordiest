import SwiftUI
import UIKit
import WordiestCore

struct ConfettiView: UIViewRepresentable {
    var tiles: [Tile]
    var palette: ColorPalette
    var isEmitting: Bool

    func makeUIView(context: Context) -> TileConfettiEmitterView {
        TileConfettiEmitterView(tiles: tiles, palette: palette)
    }

    func updateUIView(_ uiView: TileConfettiEmitterView, context: Context) {
        uiView.updateIfNeeded(tiles: tiles, palette: palette)
        uiView.setEmitting(isEmitting)
    }
}

final class TileConfettiEmitterView: UIView {
    private var tiles: [Tile]
    private var palette: ColorPalette
    private var lastBoundsSize: CGSize = .zero
    private var cachedCells: [CAEmitterCell] = []

    override class var layerClass: AnyClass {
        CAEmitterLayer.self
    }

    private var emitterLayer: CAEmitterLayer {
        // swiftlint:disable:next force_cast
        layer as! CAEmitterLayer
    }

    init(tiles: [Tile], palette: ColorPalette) {
        self.tiles = tiles
        self.palette = palette
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
        // Fountain from the bottom-center.
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY - 6)
        emitterLayer.emitterSize = CGSize(width: 1, height: 1)

        if lastBoundsSize != bounds.size {
            lastBoundsSize = bounds.size
            cachedCells = Self.cells(tiles: tiles, palette: palette, bounds: bounds)
            emitterLayer.emitterCells = cachedCells
        }
    }

    func updateIfNeeded(tiles: [Tile], palette: ColorPalette) {
        if self.tiles == tiles, self.palette == palette { return }
        self.tiles = tiles
        self.palette = palette
        cachedCells = Self.cells(tiles: tiles, palette: palette, bounds: bounds)
        emitterLayer.emitterCells = cachedCells
    }

    private func configure() {
        let emitter = emitterLayer
        emitter.emitterShape = .point
        emitter.renderMode = .oldestFirst
        emitter.birthRate = 1.0
        cachedCells = Self.cells(tiles: tiles, palette: palette, bounds: bounds)
        emitter.emitterCells = cachedCells
    }

    private static func cells(tiles: [Tile], palette: ColorPalette, bounds: CGRect) -> [CAEmitterCell] {
        let scale = UIScreen.main.scale
        let imageWidth: CGFloat = 84
        let imageSize = CGSize(width: imageWidth, height: imageWidth * WordiestTileStyle.aspectRatio)
        let tileFill = palette.uiBackground
        let tileInk = palette.uiForeground

        let height = max(1, bounds.height)
        let targetPeakHeight = height * 0.80
        // Higher acceleration makes a faster "up then down" cycle.
        let yAcceleration = max(1800, height * 2.0)
        let baseVelocity = sqrt(2.0 * yAcceleration * targetPeakHeight)
        let velocityRange = baseVelocity * 0.22
        let emissionRange: CGFloat = CGFloat.pi / 10

        // If there are too few tiles, repeat them so the effect has enough variety.
        var pool = tiles
        if pool.isEmpty {
            pool = [Tile(letter: "W", value: 4, bonus: "4W")]
        }
        while pool.count < 18 {
            pool.append(contentsOf: tiles)
            if pool.count > 40 { break }
        }

        // Too many distinct cells makes the emission look "wavy" (each cell has its own randomness).
        // Keep a small set and let each emit continuously.
        let distinct = Array(pool.prefix(8))

        return distinct.map { tile in
            let cell = CAEmitterCell()

            cell.birthRate = 7.5
            cell.lifetime = 3.0
            cell.lifetimeRange = 0.6

            cell.velocity = baseVelocity
            cell.velocityRange = velocityRange
            cell.yAcceleration = yAcceleration
            cell.xAcceleration = 0

            // Fountain upward, with a little spray.
            cell.emissionLongitude = -.pi / 2
            cell.emissionRange = emissionRange

            cell.spin = 2.8
            cell.spinRange = 3.6

            cell.scale = 0.22
            cell.scaleRange = 0.08
            cell.alphaSpeed = -0.20

            let image = WordiestTileRenderer.image(tile: tile, size: imageSize, background: tileFill, foreground: tileInk, stroke: tileInk, scale: scale)
            cell.contents = image.cgImage
            return cell
        }
    }

    func setEmitting(_ isEmitting: Bool) {
        emitterLayer.birthRate = isEmitting ? 1.0 : 0.0
    }
}
