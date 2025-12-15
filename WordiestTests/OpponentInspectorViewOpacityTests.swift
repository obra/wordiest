import SwiftUI
import UIKit
import WordiestCore
import XCTest
@testable import Wordiest

final class OpponentInspectorViewOpacityTests: XCTestCase {
    @MainActor
    func testOpponentInspectorBackgroundIsOpaque() {
        let suiteName = "OpponentInspectorViewOpacityTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = AppSettings(defaults: defaults)
        settings.colorPaletteIndex = 1

        let model = AppModel(settings: settings, historyStore: HistoryStore(), gameCenter: GameCenterNoop())
        let match = Match(
            tiles: [Tile(letter: "a", value: 1)],
            scoreSamples: [ScoreSample(score: 10, ratingX10: 500, wordsEncoding: nil)]
        )

        let palette = settings.palette
        let behindColor = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)
        let content = ZStack {
            Rectangle().fill(behindColor)
            OpponentInspectorView(model: model, match: match, sampleIndex: 0, maxWidth: 260)
                .padding(12)
        }
        .frame(width: 320, height: 220)

        guard let image = renderToImage(content, size: CGSize(width: 320, height: 220)) else {
            XCTFail("Unable to render OpponentInspectorView")
            return
        }

        // Confirm our background is being rendered.
        let backgroundSample = image.pixelColor(at: CGPoint(x: 5, y: 5))
        XCTAssertTrue(backgroundSample.isClose(to: UIColor(red: 1, green: 0, blue: 0, alpha: 1), tolerance: 0.05), "Expected background to be red, got \(backgroundSample)")

        let inspectorPixelCount = image.countPixelsClose(to: palette.uiBackground, tolerance: 0.12, step: 3)
        XCTAssertGreaterThan(inspectorPixelCount, 50, "Expected to find opaque inspector background pixels, got \(inspectorPixelCount)")
    }
}

private final class GameCenterNoop: GameCenterSubmitting {
    func submit(scoreSubmissions: [GameCenterScoreSubmission]) {}
}

@MainActor
private func renderToImage<V: View>(_ view: V, size: CGSize) -> UIImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(size)
    return renderer.uiImage
}

private extension UIColor {
    func isClose(to other: UIColor, tolerance: CGFloat) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) <= tolerance && abs(g1 - g2) <= tolerance && abs(b1 - b2) <= tolerance && abs(a1 - a2) <= tolerance
    }
}

private extension UIImage {
    func pixelColor(at point: CGPoint) -> UIColor {
        guard let cg = cgImage else { return .clear }
        let scale = scale
        let x = Int(point.x * scale)
        let y = Int(point.y * scale)
        guard x >= 0, y >= 0, x < cg.width, y < cg.height else { return .clear }
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else { return .clear }

        var pixel: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: info) else {
            return .clear
        }
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        return UIColor(
            red: CGFloat(pixel[0]) / 255.0,
            green: CGFloat(pixel[1]) / 255.0,
            blue: CGFloat(pixel[2]) / 255.0,
            alpha: CGFloat(pixel[3]) / 255.0
        )
    }

    func countPixelsClose(to color: UIColor, tolerance: CGFloat, step: Int) -> Int {
        guard step > 0 else { return 0 }
        guard let cg = cgImage else { return 0 }

        let width = cg.width
        let height = cg.height
        guard width > 0, height > 0 else { return 0 }

        var targetR: CGFloat = 0
        var targetG: CGFloat = 0
        var targetB: CGFloat = 0
        var targetA: CGFloat = 0
        guard color.getRed(&targetR, green: &targetG, blue: &targetB, alpha: &targetA) else { return 0 }

        var data = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: info) else {
            return 0
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        var count = 0
        for y in stride(from: 0, to: height, by: step) {
            let rowBase = y * width * 4
            for x in stride(from: 0, to: width, by: step) {
                let i = rowBase + (x * 4)
                let r = CGFloat(data[i]) / 255.0
                let g = CGFloat(data[i + 1]) / 255.0
                let b = CGFloat(data[i + 2]) / 255.0
                let a = CGFloat(data[i + 3]) / 255.0
                if abs(r - targetR) <= tolerance && abs(g - targetG) <= tolerance && abs(b - targetB) <= tolerance && abs(a - targetA) <= tolerance {
                    count += 1
                }
            }
        }
        return count
    }
}
