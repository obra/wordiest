import GameKit
import SwiftUI

struct LeadersView: View {
    @ObservedObject var model: AppModel
    @State private var showingGameCenter = false
    @State private var gameCenterDestination: GameCenterView.Destination = .leaderboards
    @State private var showingSignInAlert = false

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Spacer()
                Text("Leaders")
                    .font(.title.bold())
                    .foregroundStyle(palette.foreground)
                VStack(spacing: 10) {
                    leaderboardButton(title: "Total Points (All Time)", id: GameCenterLeaderboards.totalPointsAllTimeID)
                    leaderboardButton(title: "Best Round Score", id: GameCenterLeaderboards.bestRoundScoreID)
                    leaderboardButton(title: "Rating Percent", id: GameCenterLeaderboards.ratingPercentID)
                    Button("All Leaderboards") {
                        openLeaderboards(destination: .leaderboards)
                    }
                    .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
                }
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
            GameCenterView(destination: gameCenterDestination) {
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

    private func leaderboardButton(title: String, id: String) -> some View {
        let palette = model.settings.palette
        return Button(title) {
            openLeaderboards(destination: .leaderboard(id: id))
        }
        .buttonStyle(WordiestCapsuleButtonStyle(palette: palette))
    }

    private func openLeaderboards(destination: GameCenterView.Destination) {
        if GKLocalPlayer.local.isAuthenticated {
            gameCenterDestination = destination
            showingGameCenter = true
        } else {
            model.gameCenter.authenticateIfNeeded()
            showingSignInAlert = true
        }
    }
}
