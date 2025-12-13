import SwiftUI

struct SplashView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 16) {
            Spacer()

            Text("Wordiest")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(palette.foreground)

            Text(summaryText())
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
                .padding(.horizontal, 24)

            if model.isLoadingAssets {
                Text("Loading…")
                    .foregroundStyle(palette.faded)
            }

            VStack(spacing: 10) {
                Button("Play") { model.startPlay() }
                    .disabled(model.isLoadingAssets)
                Button("History") { model.showHistory() }
                    .disabled(model.isLoadingAssets)
                Button("Help") { model.showHelp() }
                Button("Credits") { model.showCredits() }
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Text("Definitions powered by Wiktionary.org")
                .font(.footnote)
                .foregroundStyle(palette.faded)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
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

