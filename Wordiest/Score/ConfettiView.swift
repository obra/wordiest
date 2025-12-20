import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false

        let emitter = CAEmitterLayer()
        emitter.emitterShape = .line
        emitter.emitterPosition = CGPoint(x: 0, y: -10)
        emitter.emitterSize = CGSize(width: 1, height: 1)
        emitter.emitterMode = .outline
        emitter.emitterCells = Self.cells()

        view.layer.addSublayer(emitter)
        context.coordinator.emitter = emitter
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.emitter?.emitterPosition = CGPoint(x: uiView.bounds.midX, y: -10)
        context.coordinator.emitter?.emitterSize = CGSize(width: uiView.bounds.width, height: 1)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var emitter: CAEmitterLayer?
    }

    private static func cells() -> [CAEmitterCell] {
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemYellow, .systemOrange, .systemPurple, .systemPink,
        ]

        return colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 4
            cell.lifetime = 4.0
            cell.velocity = 180
            cell.velocityRange = 90
            cell.yAcceleration = 260
            cell.emissionLongitude = .pi / 2
            cell.emissionRange = .pi / 3
            cell.spin = 2.2
            cell.spinRange = 3.2
            cell.scale = 0.03
            cell.scaleRange = 0.02
            cell.alphaSpeed = -0.18
            cell.color = color.cgColor

            // Simple rectangle confetti.
            let size = CGSize(width: 18, height: 10)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                ctx.cgContext.setFillColor(UIColor.white.cgColor)
                ctx.cgContext.fill(CGRect(origin: .zero, size: size))
            }
            cell.contents = image.cgImage
            return cell
        }
    }
}
