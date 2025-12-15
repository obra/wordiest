import SwiftUI
import UIKit
import WordiestCore

struct WordiestTileView: View {
    enum Kind: Equatable {
        case tile(Tile)
        case plus
    }

    var palette: ColorPalette
    var kind: Kind
    var width: CGFloat

    var body: some View {
        let height = width * WordiestTileStyle.aspectRatio
        let cornerRadius = width * WordiestTileStyle.cornerRadiusRatio
        let borderWidth = max(1, width * WordiestTileStyle.borderWidthRatio)
        let tileOffsetY = height * WordiestTileStyle.tileOffsetYRatio
        let bodyHeight = height - (tileOffsetY * 2)
        let smallFontSize = width * WordiestTileStyle.smallFontRatio

        ZStack {
            switch kind {
	            case let .tile(t):
	                let scale = UIScreen.main.scale
	                let smallUIFont = UIFont(name: "IstokWeb-Bold", size: smallFontSize) ?? .systemFont(ofSize: smallFontSize, weight: .bold)
	                let edgePadding = width * WordiestTileStyle.padding3dpRatio
	                let valuePadding = width * WordiestTileStyle.padding6dpRatio

                if let bonus = t.bonus, !bonus.isEmpty {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(palette.foreground, lineWidth: borderWidth)
                        .frame(width: width * 0.5, height: height)
                }

                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(palette.foreground, lineWidth: borderWidth)
                    .frame(width: width, height: bodyHeight)

                if let bonus = t.bonus, !bonus.isEmpty {
                    // Put the bonus fill *above* the body stroke so it erases the stroke segment that
                    // would otherwise appear as a line across the tab/body overlap.
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(palette.background)
                        .frame(width: width * 0.5, height: height)
                }

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(palette.background)
                    .frame(width: width, height: bodyHeight)

                if let bonus = t.bonus, !bonus.isEmpty {
                    let bonusText = bonus.uppercased()
                    let bonusImage = GlyphBoundsText.image(text: bonusText, font: smallUIFont, scale: scale)

                    Image(uiImage: bonusImage)
                        .renderingMode(.template)
                        .foregroundStyle(palette.foreground)
                        .position(x: width / 2.0, y: edgePadding + (bonusImage.size.height / 2.0))

                    Image(uiImage: bonusImage)
                        .renderingMode(.template)
                        .foregroundStyle(palette.foreground)
                        .position(x: width / 2.0, y: height - edgePadding - (bonusImage.size.height / 2.0))
                }

                Text(t.letter.uppercased())
                    .font(.custom("IstokWeb-Bold", size: width * WordiestTileStyle.letterFontRatio))
                    .foregroundStyle(palette.foreground)

	                if t.value > 0 {
	                    let valueImage = GlyphBoundsText.image(text: String(t.value), font: smallUIFont, scale: scale)
	                    Image(uiImage: valueImage)
	                        .renderingMode(.template)
	                        .foregroundStyle(palette.foreground)
	                        .position(
	                            x: width - valuePadding - (valueImage.size.width / 2.0),
	                            y: height - tileOffsetY - valuePadding - (valueImage.size.height / 2.0)
	                        )
	                }
            case .plus:
                Text("+")
                    .font(.custom("IstokWeb-Bold", size: width * WordiestTileStyle.letterFontRatio))
                    .foregroundStyle(palette.foreground)
            }
        }
        .frame(width: width, height: height)
    }
}
