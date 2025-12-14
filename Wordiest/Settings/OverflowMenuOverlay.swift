import SwiftUI
import UIKit

struct OverflowMenuOverlay: View {
    @ObservedObject var model: AppModel
    @Binding var isPresented: Bool

    var onBack: (() -> Void)?

    @State private var isConfirmingReset = false
    @State private var isPresentingShare = false

    var body: some View {
        if isPresented {
            let palette = model.settings.palette
            ZStack(alignment: .bottomTrailing) {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }

                VStack(alignment: .leading, spacing: 0) {
                    if let onBack {
                        menuButton("Back", palette: palette) {
                            isPresented = false
                            onBack()
                        }
                        Divider().background(palette.faded.opacity(0.6))
                    }

                    menuButton("Change colors", palette: palette) {
                        model.settings.colorPaletteIndex = (model.settings.colorPaletteIndex % 6) + 1
                        model.applySettingsToScene()
                        isPresented = false
                    }
                    Divider().background(palette.faded.opacity(0.6))

                    menuButton("Share screenshot", palette: palette) {
                        isPresentingShare = true
                    }
                    Divider().background(palette.faded.opacity(0.6))

                    menuButton(model.settings.soundEnabled ? "Disable sound" : "Enable sound", palette: palette) {
                        model.settings.soundEnabled.toggle()
                        model.applySettingsToScene()
                        isPresented = false
                    }
                    Divider().background(palette.faded.opacity(0.6))

                    menuButton("Reset rating", palette: palette, role: .destructive) {
                        isConfirmingReset = true
                    }
                    Divider().background(palette.faded.opacity(0.6))

                    menuButton("Privacy policy", palette: palette) {
                        if let url = URL(string: "https://concreterose.github.io/privacypolicy.html") {
                            UIApplication.shared.open(url)
                        }
                        isPresented = false
                    }
                    Divider().background(palette.faded.opacity(0.6))

                    menuButton("Help", palette: palette) {
                        isPresented = false
                        model.showHelp()
                    }
                    Divider().background(palette.faded.opacity(0.6))

                    menuButton("About game", palette: palette) {
                        isPresented = false
                        model.showCredits()
                    }
                }
                .frame(width: 240)
                .background(palette.background)
                .overlay(Rectangle().stroke(palette.faded.opacity(0.8), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 6)
                .padding(.trailing, 12)
                .padding(.bottom, 50 + 12)
            }
            .alert("Confirm", isPresented: $isConfirmingReset) {
                Button("Cancel", role: .cancel) {
                    isConfirmingReset = false
                }
                Button("Reset", role: .destructive) {
                    model.settings.resetRatingAndStats()
                    model.historyStore.clear()
                    model.applySettingsToScene()
                    isConfirmingReset = false
                    isPresented = false
                    model.returnToSplash()
                }
            } message: {
                Text("Reset rating and clear history?")
            }
            .sheet(isPresented: $isPresentingShare) {
                ShareScreenshotView(model: model)
            }
        }
    }

    private func menuButton(_ title: String, palette: ColorPalette, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Text(title)
                .font(.system(size: 18))
                .foregroundStyle(role == .destructive ? Color.red : palette.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(WordiestMenuRowButtonStyle(palette: palette))
    }
}

private struct WordiestMenuRowButtonStyle: ButtonStyle {
    var palette: ColorPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color(uiColor: WordiestButtonColors.backgroundUIColor(palette: palette, isPressed: configuration.isPressed)))
    }
}

