import SwiftUI

struct CreditsView: View {
    @ObservedObject var model: AppModel

    @State private var isPresentingLookup = false
    @State private var isShowingOriginalCredits = false

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Wordiest")
                        .font(.title.bold())
                        .foregroundStyle(palette.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Original game by Darrell Anderson")
                        .font(.title2.bold())
                        .foregroundStyle(palette.foreground)

                    Text("iOS port by Jesse Vincent")
                        .font(.headline)
                        .foregroundStyle(palette.foreground)

                    VStack(alignment: .leading, spacing: 10) {
                        Link("Privacy policy", destination: AppLinks.privacyPolicy)
                        Link("Source code", destination: AppLinks.sourceCode)
                    }
                    .font(.headline)
                    .foregroundStyle(palette.foreground)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current attributions")
                            .font(.headline)
                            .foregroundStyle(palette.foreground)

                        Text("This iOS port reuses some content and assets from the original Android release. See the repository README for a full inventory.")
                            .foregroundStyle(palette.foreground)

                        VStack(alignment: .leading, spacing: 8) {
                            HTMLText(
                                html: """
                                <b>Wiktionary</b><br>
                                Words and definitions<br>
                                http://wiktionary.org
                                """,
                                textColor: palette.foreground
                            )
                            HTMLText(
                                html: """
                                <b>SOWPODS</b><br>
                                Canonical list of English words
                                """,
                                textColor: palette.foreground
                            )
                            HTMLText(
                                html: """
                                <b>Istok Web</b><br>
                                Font (SIL Open Font License 1.1)
                                """,
                                textColor: palette.foreground
                            )
                            HTMLText(
                                html: """
                                <b>FreeSFX</b><br>
                                Sounds<br>
                                http://www.freesfx.co.uk
                                """,
                                textColor: palette.foreground
                            )
                        }
                        .font(.callout)
                    }

                    DisclosureGroup(isExpanded: $isShowingOriginalCredits) {
                        Text("Shown for historical reference; the iOS port does not use all of the components credited by the Android release.")
                            .font(.footnote)
                            .foregroundStyle(palette.foreground.opacity(0.75))
                            .padding(.bottom, 8)

                        HTMLText(html: AppCopy.originalAndroidCreditsHTML, textColor: palette.foreground)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Text("Original Android credits")
                            .font(.headline)
                            .foregroundStyle(palette.foreground)
                    }

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

            WordiestBottomBar(palette: palette) {
                Button("Back") { model.returnToSplash() }
                    .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
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
