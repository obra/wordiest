import SwiftUI
import UIKit

struct MenuView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var isConfirmingReset = false
    @State private var isPresentingShare = false
    @State private var capturedShareImage: UIImage?

    var body: some View {
        let palette = model.settings.palette
        NavigationStack {
            List {
                Section {
                    Picker(
                        "Appearance",
                        selection: Binding(
                            get: { model.settings.themeMode },
                            set: { newValue in
                                model.settings.themeMode = newValue
                                model.applySettingsToScene()
                            }
                        )
                    ) {
                        ForEach(AppSettings.ThemeMode.allCases, id: \.rawValue) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    Button("Share screenshot") {
                        capturedShareImage = ScreenshotCapture.capture()
                        isPresentingShare = true
                    }

                    Toggle(
                        isOn: Binding(
                            get: { model.settings.soundEnabled },
                            set: { newValue in
                                model.settings.soundEnabled = newValue
                                model.applySettingsToScene()
                            }
                        )
                    ) {
                        Text(model.settings.soundEnabled ? "Disable sound" : "Enable sound")
                    }

                    Button("Reset rating") {
                        isConfirmingReset = true
                    }
                    .foregroundStyle(.red)

                    Button("Privacy policy") {
                        model.openPrivacyPolicy()
                    }
                }

                Section {
                    Button("Help") {
                        dismiss()
                        model.showHelp()
                    }
                    Button("About game") {
                        dismiss()
                        model.showCredits()
                    }
                }
            }
            .foregroundStyle(palette.foreground)
            .scrollContentBackground(.hidden)
            .background(palette.background)
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: model.settings.themeMode) { _, _ in
                model.applySettingsToScene()
            }
            .alert("Confirm", isPresented: $isConfirmingReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    model.settings.resetRatingAndStats()
                    model.historyStore.clear()
                    model.applySettingsToScene()
                    dismiss()
                    model.returnToSplash()
                }
            } message: {
                Text("Reset rating and clear history?")
            }
        }
        .tint(palette.foreground)
        .sheet(isPresented: $isPresentingShare) {
            ShareScreenshotView(model: model, initialImage: capturedShareImage)
        }
    }
}
