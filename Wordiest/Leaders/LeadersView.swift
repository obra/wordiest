import GameKit
import SwiftUI

struct LeadersView: View {
    @ObservedObject var model: AppModel
    @State private var showingGameCenter = false
    @State private var showingSignInAlert = false

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Spacer()
                Text("Leaders")
                    .font(.title.bold())
                    .foregroundStyle(palette.foreground)
                Button("Show Leaderboards") {
                    if GKLocalPlayer.local.isAuthenticated {
                        showingGameCenter = true
                    } else {
                        model.gameCenter.authenticateIfNeeded()
                        showingSignInAlert = true
                    }
                }
                .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                Spacer()
            }

            WordiestBottomBar(palette: palette) {
                Button("Back") { model.returnToSplash() }
                    .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
            }
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
        .alert("Game Center Sign-In Required", isPresented: $showingSignInAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Sign in to Game Center in Settings to view leaderboards and post scores.")
        }
    }
}
