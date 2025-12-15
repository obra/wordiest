import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            switch model.route {
            case .splash:
                SplashView(model: model)
                    .transition(WordiestMotion.routeTransition(reduceMotion: reduceMotion))
            case .match:
                MatchView(model: model)
                    .transition(WordiestMotion.routeTransition(reduceMotion: reduceMotion))
            case let .score(context):
                ScoreView(model: model, context: context)
                    .transition(WordiestMotion.routeTransition(reduceMotion: reduceMotion))
            case .history:
                HistoryView(model: model)
                    .transition(WordiestMotion.routeTransition(reduceMotion: reduceMotion))
            case .leaders:
                LeadersView(model: model)
                    .transition(WordiestMotion.routeTransition(reduceMotion: reduceMotion))
            case .credits:
                CreditsView(model: model)
                    .transition(WordiestMotion.routeTransition(reduceMotion: reduceMotion))
            case .help:
                HelpView(model: model)
                    .transition(WordiestMotion.routeTransition(reduceMotion: reduceMotion))
            }
        }
        .preferredColorScheme(preferredColorSchemeOverride())
        .animation(WordiestMotion.routeAnimation(reduceMotion: reduceMotion), value: model.route)
        .onAppear {
            model.settings.effectiveColorScheme = colorScheme
            model.applySettingsToScene()
        }
        .onChange(of: colorScheme) { _, newValue in
            model.settings.effectiveColorScheme = newValue
            model.applySettingsToScene()
        }
    }

    private func preferredColorSchemeOverride() -> ColorScheme? {
        switch model.settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
