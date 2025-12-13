import SwiftUI

struct ScoreGraphView: View {
    var palette: ColorPalette
    var points: [CGPoint]
    var center: CGPoint
    var highlightIndex: Int?

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 12, dy: 12)
                let mapping = ScoreGraphMath.mappedPoints(points: points, center: center, rect: rect)

                var background = Path(rect)
                context.fill(background, with: .color(palette.background))

                let midX = rect.midX
                let midY = rect.midY

                context.fill(Path(CGRect(x: rect.minX, y: rect.minY, width: midX - rect.minX, height: midY - rect.minY)), with: .color(Color(white: 0.12)))
                context.fill(Path(CGRect(x: midX, y: rect.minY, width: rect.maxX - midX, height: midY - rect.minY)), with: .color(Color(white: 0.08)))
                context.fill(Path(CGRect(x: rect.minX, y: midY, width: midX - rect.minX, height: rect.maxY - midY)), with: .color(Color(white: 0.08)))
                context.fill(Path(CGRect(x: midX, y: midY, width: rect.maxX - midX, height: rect.maxY - midY)), with: .color(Color(white: 0.12)))

                var axis = Path()
                axis.move(to: CGPoint(x: rect.minX, y: midY))
                axis.addLine(to: CGPoint(x: rect.maxX, y: midY))
                axis.move(to: CGPoint(x: midX, y: rect.minY))
                axis.addLine(to: CGPoint(x: midX, y: rect.maxY))
                context.stroke(axis, with: .color(palette.foreground.opacity(0.6)), lineWidth: 1)

                for (idx, p) in mapping.mapped.enumerated() {
                    let isHighlight = highlightIndex == idx
                    let dotRect = CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)
                    context.fill(Path(ellipseIn: dotRect), with: .color(isHighlight ? .red : palette.foreground))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
