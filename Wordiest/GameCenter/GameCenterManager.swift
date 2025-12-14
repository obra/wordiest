import Foundation
import GameKit
import UIKit

@MainActor
protocol GameCenterSubmitting {
    func authenticateIfNeeded()
    func submit(scoreSubmissions: [GameCenterScoreSubmission])
}

extension GameCenterSubmitting {
    func authenticateIfNeeded() {}
}

@MainActor
protocol GameCenterClient {
    var isAuthenticated: Bool { get }
    func report(scores: [GameCenterScoreSubmission])
    func authenticate(present: @escaping (UIViewController) -> Void)
}

@MainActor
final class GameCenterManager: GameCenterSubmitting {
    private let client: GameCenterClient

    init(client: GameCenterClient = GameKitGameCenterClient()) {
        self.client = client
    }

    func authenticateIfNeeded() {
        client.authenticate { viewController in
            guard let presenter = Self.activePresenter() else { return }
            presenter.present(viewController, animated: true)
        }
    }

    func submit(scoreSubmissions: [GameCenterScoreSubmission]) {
        guard client.isAuthenticated else { return }
        client.report(scores: scoreSubmissions)
    }

    private static func activePresenter() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return nil
        }
        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

@MainActor
private final class GameKitGameCenterClient: GameCenterClient {
    var isAuthenticated: Bool {
        GKLocalPlayer.local.isAuthenticated
    }

    func authenticate(present: @escaping (UIViewController) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { viewController, _ in
            guard let viewController else { return }
            present(viewController)
        }
    }

    func report(scores: [GameCenterScoreSubmission]) {
        let toReport: [GKScore] = scores.map { submission in
            let score = GKScore(leaderboardIdentifier: submission.leaderboardID)
            score.value = Int64(submission.score)
            return score
        }
        GKScore.report(toReport) { _ in }
    }
}
