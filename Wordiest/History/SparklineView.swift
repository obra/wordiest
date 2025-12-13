import SwiftUI

struct SparklineView: View {
    var palette: ColorPalette
    var ratings: [Double]          // oldest -> newest
    var expectedDelta: [Double]    // same count as ratings
    var highlightStart: Int?
    var highlightEnd: Int?

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3)

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.background))

            guard !ratings.isEmpty else { return }
            let mm = SparklineMath.ratingMinMax(ratings: ratings)
            let minY = mm.min
            let maxY = mm.max
            let ySpan = maxY - minY

            func mapX(_ index: Int) -> CGFloat {
                if ratings.count <= 1 { return rect.midX }
                return rect.minX + (CGFloat(index) * rect.width / CGFloat(ratings.count - 1))
            }
            func mapY(_ rating: Double) -> CGFloat {
                if ySpan == 0 { return rect.midY }
                return rect.minY + rect.height * CGFloat((maxY - rating) / ySpan)
            }

            if let start = highlightStart, let end = highlightEnd, start != end {
                let x1 = mapX(min(start, end))
                let x2 = mapX(max(start, end))
                context.fill(Path(CGRect(x: x1, y: rect.minY, width: x2 - x1, height: rect.height)), with: .color(palette.faded))
            }

            var prev: CGPoint?
            for i in 0..<ratings.count {
                let point = CGPoint(x: mapX(i), y: mapY(ratings[i]))

                var color = palette.foreground
                if i > 0 {
                    let actual = ratings[i] - ratings[i - 1]
                    if SparklineMath.isAbnormal(expectedDelta: expectedDelta[i], actualDelta: actual) {
                        color = .red
                    }
                }

                if let prev {
                    var path = Path()
                    path.move(to: prev)
                    path.addLine(to: point)
                    context.stroke(path, with: .color(color), lineWidth: 2)
                }
                context.fill(Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)), with: .color(color))
                prev = point
            }
        }
        .frame(height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

