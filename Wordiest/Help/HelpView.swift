import SwiftUI

struct HelpView: View {
    @ObservedObject var model: AppModel

    @State private var selectedTitle: String = HelpPages.pages.first?.title ?? "Playing"

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 0) {
            TabView(selection: $selectedTitle) {
                ForEach(HelpPages.pages) { page in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Help")
                                .font(.title.bold())
                                .foregroundStyle(palette.foreground)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(page.title)
                                .font(.headline)
                                .foregroundStyle(palette.foreground)

                            HTMLText(html: page.html, textColor: palette.foreground)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if page.title == "Sharing" {
                                Text("Note: This iOS port does not include achievements or cloud save.")
                                    .font(.footnote)
                                    .foregroundStyle(palette.foreground.opacity(0.75))
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                    }
                    .tag(page.title)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            WordiestBottomBar(palette: palette) {
                Button("Back") { model.returnToSplash() }
                    .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .tint(palette.foreground)
    }
}
