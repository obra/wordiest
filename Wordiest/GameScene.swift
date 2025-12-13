import SpriteKit

final class GameScene: SKScene {
    func configure(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        if self.size != size {
            self.size = size
        }
        if scaleMode != .resizeFill {
            scaleMode = .resizeFill
        }
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
    }
}

