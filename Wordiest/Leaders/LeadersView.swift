import SwiftUI

struct LeadersView: View {
    @ObservedObject var model: AppModel
    @State private var showingGameCenter = false

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 12) {
            HStack {
                Button("Back") { model.returnToSplash() }
                    .buttonStyle(.plain)
                    .foregroundStyle(palette.foreground)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            Spacer()
            Text("Leaders")
                .font(.title.bold())
                .foregroundStyle(palette.foreground)
            Button("Show Leaderboards") { showingGameCenter = true }
                .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .tint(palette.foreground)
        .onAppear {
            model.gameCenter.authenticateIfNeeded()
        }
        .sheet(isPresented: $showingGameCenter) {
            GameCenterView(state: .leaderboards) {
                showingGameCenter = false
            }
            .ignoresSafeArea()
        }
    }
}
