import SwiftUI

struct WordiestMenu: View {
    @ObservedObject var model: AppModel
    var onBack: (() -> Void)?

    @State private var isConfirmingReset = false
    @State private var isPresentingShare = false
    @State private var capturedShareImage: UIImage?

    var body: some View {
        Menu {
            if let onBack {
                Button("Back") { onBack() }
            }

            Menu("Appearance") {
                appearanceButton(title: AppSettings.ThemeMode.system.title, mode: .system)
                appearanceButton(title: AppSettings.ThemeMode.light.title, mode: .light)
                appearanceButton(title: AppSettings.ThemeMode.dark.title, mode: .dark)
            }

            Button("Share screenshot") {
                DispatchQueue.main.async {
                    capturedShareImage = ScreenshotCapture.capture()
                    isPresentingShare = true
                }
            }

            Toggle(isOn: Binding(get: { model.settings.soundEnabled }, set: { newValue in
                model.settings.soundEnabled = newValue
                model.applySettingsToScene()
            })) {
                Text("Sound")
            }

            Button(role: .destructive) {
                isConfirmingReset = true
            } label: {
                Text("Reset rating")
            }

            Button("Privacy policy") {
                model.openPrivacyPolicy()
            }

            Button("Help") { model.showHelp() }
            Button("About game") { model.showCredits() }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20, weight: .semibold))
        }
        .sheet(isPresented: $isPresentingShare) {
            ShareScreenshotView(model: model, initialImage: capturedShareImage)
        }
        .alert("Confirm", isPresented: $isConfirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                model.resetRatingAndHistory()
                if model.route != .splash {
                    model.returnToSplash()
                }
            }
        } message: {
            Text("Reset rating and clear history?")
        }
    }

    private func appearanceButton(title: String, mode: AppSettings.ThemeMode) -> some View {
        Button {
            model.settings.themeMode = mode
            model.applySettingsToScene()
        } label: {
            if model.settings.themeMode == mode {
                Text("\(title) ✓")
            } else {
                Text(title)
            }
        }
    }
}
