import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
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
        .preferredColorScheme(preferredColorSchemeOverride())
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
