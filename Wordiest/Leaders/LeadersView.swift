import SwiftUI

struct LeadersView: View {
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
            Text("Leaders")
                .font(.title.bold())
                .foregroundStyle(palette.foreground)
            Text("Leaderboards aren’t available in this iOS port.")
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
                .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }
}

