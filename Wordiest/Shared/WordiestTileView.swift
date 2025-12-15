import SwiftUI
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
                    let topBaselineY = height * WordiestTileStyle.bonusTopBaselineFromTopRatio
                    let bottomBaselineY = height - (height * WordiestTileStyle.bonusBottomBaselineFromBottomRatio)

                    ZStack(alignment: .top) {
                        Text(bonusText)
                            .font(.custom("IstokWeb-Bold", size: smallFontSize))
                            .foregroundStyle(palette.foreground)
                            .alignmentGuide(.top) { dimensions in
                                topBaselineY - dimensions[.firstTextBaseline]
                            }

                        Text(bonusText)
                            .font(.custom("IstokWeb-Bold", size: smallFontSize))
                            .foregroundStyle(palette.foreground)
                            .alignmentGuide(.top) { dimensions in
                                bottomBaselineY - dimensions[.firstTextBaseline]
                            }
                    }
                    .frame(width: width, height: height)
                }

                Text(t.letter.uppercased())
                    .font(.custom("IstokWeb-Bold", size: width * WordiestTileStyle.letterFontRatio))
                    .foregroundStyle(palette.foreground)

                if t.value > 0 {
                    VStack {
                        Spacer(minLength: 0)
                        HStack {
                            Spacer(minLength: 0)
                            Text(String(t.value))
                                .font(.custom("IstokWeb-Bold", size: smallFontSize))
                                .foregroundStyle(palette.foreground)
                                .padding(.trailing, width * WordiestTileStyle.padding7dpRatio)
                                .padding(.bottom, tileOffsetY + (width * WordiestTileStyle.padding7dpRatio))
                        }
                    }
                    .frame(width: width, height: height)
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
