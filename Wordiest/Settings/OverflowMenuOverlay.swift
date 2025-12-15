import SwiftUI
import UIKit

struct OverflowMenuOverlay: View {
    @ObservedObject var model: AppModel
    @Binding var isPresented: Bool

    var onBack: (() -> Void)?

    @State private var isConfirmingReset = false
    @State private var isPresentingShare = false
    @State private var capturedShareImage: UIImage?

    var body: some View {
        if isPresented {
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }

                VStack(alignment: .leading, spacing: 0) {
                    if let onBack {
                        menuButton("Back") {
                            isPresented = false
                            onBack()
                        }
                        Divider()
                    }

                    menuButton("Change colors") {
                        model.settings.colorPaletteIndex = (model.settings.colorPaletteIndex % 6) + 1
                        model.applySettingsToScene()
                        isPresented = false
                    }
                    Divider()

                    menuButton("Share screenshot") {
                        capturedShareImage = ScreenshotCapture.capture()
                        isPresentingShare = true
                    }
                    Divider()

                    menuButton(model.settings.soundEnabled ? "Disable sound" : "Enable sound") {
                        model.settings.soundEnabled.toggle()
                        model.applySettingsToScene()
                        isPresented = false
                    }
                    Divider()

                    menuButton("Reset rating", role: .destructive) {
                        isConfirmingReset = true
                    }
                    Divider()

                    menuButton("Privacy policy") {
                        if let url = URL(string: "https://concreterose.github.io/privacypolicy.html") {
                            UIApplication.shared.open(url)
                        }
                        isPresented = false
                    }
                    Divider()

                    menuButton("Help") {
                        isPresented = false
                        model.showHelp()
                    }
                    Divider()

                    menuButton("About game") {
                        isPresented = false
                        model.showCredits()
                    }
                }
                .frame(width: 240)
                .background(Color.white)
                .overlay(Rectangle().stroke(Color.black.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
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
                ShareScreenshotView(model: model, initialImage: capturedShareImage)
            }
        }
    }

    private func menuButton(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(role == .destructive ? Color.red : Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(WordiestMenuRowButtonStyle())
    }
}

private struct WordiestMenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.black.opacity(0.08) : Color.clear)
    }
}
