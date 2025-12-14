import SwiftUI

struct SplashView: View {
    @ObservedObject var model: AppModel
    @State private var isPresentingMenu = false

    var body: some View {
        let palette = model.settings.palette
        ZStack(alignment: .bottom) {
            VStack(spacing: 12) {
                Spacer()

                Text("Wordiest")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(palette.foreground)

                Text(summaryText())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.foreground)
                    .padding(.horizontal, 24)

                Spacer()

                Text("Definitions powered by Wiktionary.org")
                    .font(.footnote)
                    .foregroundStyle(palette.faded)
                    .padding(.bottom, 50 + 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if model.isLoadingAssets {
                Text("Loading…")
                    .font(.system(size: 18))
                    .foregroundStyle(palette.foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(palette.faded)
            } else {
                HStack(spacing: 1) {
                    Button("Play") { model.startPlay() }
                    Button("History") { model.showHistory() }
                    Button("Leaders") { model.showLeaders() }
                    Button {
                        isPresentingMenu = true
                    } label: {
                        Image("ic_core_overflow")
                            .renderingMode(.template)
                    }
                    .frame(width: 50)
                }
                .buttonStyle(WordiestBarButtonStyle(palette: palette))
                .padding(.top, 1)
                .frame(height: 50)
                .background(palette.faded)
            }

            OverflowMenuOverlay(model: model, isPresented: $isPresentingMenu)
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
