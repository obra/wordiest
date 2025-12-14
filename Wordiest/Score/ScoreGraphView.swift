import SwiftUI

struct ScoreGraphView: View {
    var palette: ColorPalette
    var points: [CGPoint]
    var center: CGPoint
    var highlightIndex: Int?

    var body: some View {
        GeometryReader { proxy in
            let inset: CGFloat = 12
            let rect = CGRect(origin: .zero, size: proxy.size).insetBy(dx: inset, dy: inset)

            ZStack {
                Canvas { context, _ in
                    let mapping = ScoreGraphMath.mappedPoints(points: points, center: center, rect: rect)

                    var background = Path(rect)
                    context.fill(background, with: .color(palette.background))

                    let midX = rect.midX
                    let midY = rect.midY

                    let shadeA = palette.faded.opacity(0.18)
                    let shadeB = palette.faded.opacity(0.10)
                    context.fill(Path(CGRect(x: rect.minX, y: rect.minY, width: midX - rect.minX, height: midY - rect.minY)), with: .color(shadeA))
                    context.fill(Path(CGRect(x: midX, y: rect.minY, width: rect.maxX - midX, height: midY - rect.minY)), with: .color(shadeB))
                    context.fill(Path(CGRect(x: rect.minX, y: midY, width: midX - rect.minX, height: rect.maxY - midY)), with: .color(shadeB))
                    context.fill(Path(CGRect(x: midX, y: midY, width: rect.maxX - midX, height: rect.maxY - midY)), with: .color(shadeA))

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

                    let centerDotRect = CGRect(x: rect.midX - 4, y: rect.midY - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: centerDotRect), with: .color(palette.foreground))
                    context.stroke(Path(ellipseIn: centerDotRect), with: .color(palette.background), lineWidth: 1)

                    context.draw(
                        Text("You")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.foreground),
                        at: CGPoint(x: rect.midX, y: rect.midY - 14),
                        anchor: .center
                    )
                }

                axisLabels(rect: rect)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func axisLabels(rect: CGRect) -> some View {
        let labelColor = palette.foreground.opacity(0.35)
        let labelFont = Font.system(size: 11)
        let midX = rect.midX
        let midY = rect.midY
        let yOffset: CGFloat = 12
        let xOffset: CGFloat = 12

        return Group {
            Text("- rating")
                .font(labelFont)
                .foregroundStyle(labelColor)
                .position(x: (rect.minX + midX) / 2, y: midY + yOffset)

            Text("rating +")
                .font(labelFont)
                .foregroundStyle(labelColor)
                .position(x: (midX + rect.maxX) / 2, y: midY + yOffset)

            Text("- score")
                .font(labelFont)
                .foregroundStyle(labelColor)
                .rotationEffect(.degrees(-90))
                .position(x: midX - xOffset, y: (midY + rect.maxY) / 2)

            Text("score +")
                .font(labelFont)
                .foregroundStyle(labelColor)
                .rotationEffect(.degrees(-90))
                .position(x: midX + xOffset, y: (rect.minY + midY) / 2)
        }
        .allowsHitTesting(false)
    }
}
