import GameKit
import SwiftUI

struct GameCenterView: UIViewControllerRepresentable {
    enum Destination: Equatable {
        case leaderboards
        case leaderboard(id: String)
    }

    var destination: Destination
    var onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc: GKGameCenterViewController
        switch destination {
        case .leaderboards:
            vc = GKGameCenterViewController(state: .leaderboards)
        case .leaderboard(let id):
            vc = GKGameCenterViewController(leaderboardID: id, playerScope: .global, timeScope: .allTime)
        }
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            onFinish()
        }
    }
}
