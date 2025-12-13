import SwiftUI

struct HelpView: View {
    @ObservedObject var model: AppModel

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

            Spacer()
            Text("Help")
                .font(.title.bold())
                .foregroundStyle(palette.foreground)
            Text("Playing / Scoring / History / Sharing")
                .foregroundStyle(palette.foreground)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }
}
