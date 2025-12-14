import SwiftUI
import WordiestCore

struct SplashView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        GeometryReader { proxy in
            let palette = model.settings.palette
            let tileWidth = min(proxy.size.width * 0.40, 180)

            ZStack(alignment: .bottom) {
                VStack(spacing: 12) {
                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: tileWidth * WordiestTileStyle.cornerRadiusRatio)
                            .fill(palette.faded)
                            .overlay(
                                RoundedRectangle(cornerRadius: tileWidth * WordiestTileStyle.cornerRadiusRatio)
                                    .strokeBorder(palette.faded, lineWidth: max(1, tileWidth * WordiestTileStyle.borderWidthRatio))
                            )
                            .frame(width: tileWidth, height: tileWidth)
                            .scaleEffect(1.3)

                        WordiestTileView(
                            palette: palette,
                            kind: .tile(Tile(letter: "W", value: 4, bonus: "5L")),
                            width: tileWidth
                        )
                        .rotationEffect(.degrees(15))
                    }
                    .padding(.bottom, 4)
                    .onTapGesture {
                        if !model.isLoadingAssets {
                            model.startPlay()
                        }
                    }

                    Text(summaryText())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.foreground)
                        .padding(.horizontal, 24)

                    Spacer()

                    Text("Definitions powered by Wiktionary.org")
                        .font(.footnote)
                        .foregroundStyle(palette.faded)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if model.isLoadingAssets {
                    Text("Loading…")
                        .font(.system(size: 18))
                        .foregroundStyle(palette.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(palette.background.opacity(0.98))
                } else {
                    WordiestBottomBar(palette: palette) {
                        Button("Play") { model.startPlay() }
                            .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                        Button("History") { model.showHistory() }
                            .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                        Button("Leaders") { model.showLeaders() }
                            .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                        WordiestMenu(model: model)
                            .frame(width: 52)
                            .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                    }
                }
            }
            .background(palette.background)
            .tint(palette.foreground)
            .highPriorityGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard !model.isLoadingAssets else { return }
                        if value.predictedEndTranslation.width < 0, abs(value.predictedEndTranslation.width) > abs(value.predictedEndTranslation.height) {
                            model.startPlay()
                        }
                    }
            )
        }
    }

    private func summaryText() -> String {
        if model.settings.numMatches == 0 {
            return "You have played no games.\nPlay to earn your wordiest rating!"
        }
        let gamesPlural = model.settings.numMatches == 1 ? "" : "s"
        let pointsPlural = model.settings.cumulativeScore == 1 ? "" : "s"
        let rating = String(format: "%.1f", model.settings.rating)
        return "You have played \(model.settings.numMatches) game\(gamesPlural)\nfor \(model.settings.cumulativeScore) total point\(pointsPlural).\n\nYour wordiest rating is \(rating)."
    }
}
