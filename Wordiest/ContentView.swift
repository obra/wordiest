import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        switch model.route {
        case .splash:
            SplashView(model: model)
        case .match:
            MatchView(model: model)
        case let .score(context):
            ScoreView(model: model, context: context)
        case .history:
            HistoryView(model: model)
        case .leaders:
            LeadersView(model: model)
        case .credits:
            CreditsView(model: model)
        case .help:
            HelpView(model: model)
        }
    }
}
