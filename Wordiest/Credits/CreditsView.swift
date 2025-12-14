import SwiftUI

struct CreditsView: View {
    @ObservedObject var model: AppModel

    @State private var isPresentingLookup = false

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 12) {
            HStack {
                Button("Back") { model.returnToSplash() }
                    .buttonStyle(.bordered)
                Spacer()
                MenuButton(model: model)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Credits")
                        .font(.title.bold())
                        .foregroundStyle(palette.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HTMLText(html: AppCopy.creditsHTML, textColor: palette.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(footerText())
                        .font(.footnote.monospaced())
                        .foregroundStyle(palette.foreground.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .onLongPressGesture(minimumDuration: 0.35) {
                            isPresentingLookup = true
                        }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .tint(palette.foreground)
        .sheet(isPresented: $isPresentingLookup) {
            if let defs = model.assets?.definitions {
                DictionaryLookupView(definitions: defs, palette: palette)
            } else {
                VStack(spacing: 12) {
                    Text("Definitions are still loading.")
                        .foregroundStyle(palette.foreground)
                    Button("OK") { isPresentingLookup = false }
                        .buttonStyle(.bordered)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
            }
        }
    }

    private func footerText() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        let rating = String(format: "%.1f", model.settings.rating)
        return "v\(version) (\(build))  user=\(model.settings.userId)  games=\(model.settings.numMatches)  rating=\(rating)"
    }
}
