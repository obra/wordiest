import SwiftUI

struct WordiestMenu: View {
    @ObservedObject var model: AppModel
    var onBack: (() -> Void)?

    @State private var isPresentingPalettePicker = false
    @State private var isConfirmingReset = false
    @State private var isPresentingShare = false

    var body: some View {
        Menu {
            if let onBack {
                Button("Back") { onBack() }
            }

            Button("Change colors") { isPresentingPalettePicker = true }

            Button("Share screenshot") { isPresentingShare = true }

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
        .sheet(isPresented: $isPresentingPalettePicker) {
            PalettePickerView(settings: model.settings)
        }
        .sheet(isPresented: $isPresentingShare) {
            ShareScreenshotView(model: model)
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
}

