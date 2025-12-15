import SpriteKit
import SwiftUI

struct MatchView: View {
    @ObservedObject var model: AppModel

    @State private var didLongPressReset = false
    @State private var wiktionaryWord: String?
    @State private var submitWarningMessage: String?
    @State private var isConfirmingLeave = false
    @State private var bottomBarHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let sceneSize = proxy.size
            ZStack(alignment: .bottom) {
                SpriteView(scene: model.scene)
                    .ignoresSafeArea()
                    .onAppear {
                        model.scene.onRequestOpenWiktionary = { word in
                            wiktionaryWord = word
                        }
                        model.configureSceneIfReady(size: sceneSize)
                        model.applySettingsToScene()
                        updateSceneInsets(proxy: proxy)
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        model.configureSceneIfReady(size: newSize)
                    }
                    .onChange(of: proxy.safeAreaInsets) { _, _ in
                        updateSceneInsets(proxy: proxy)
                    }
                    .onChange(of: model.settings.soundEnabled) { _, _ in
                        model.applySettingsToScene()
                    }
                    .onChange(of: model.settings.themeMode) { _, _ in
                        model.applySettingsToScene()
                    }
                    .onChange(of: model.settings.effectiveColorScheme) { _, _ in
                        model.applySettingsToScene()
                    }

                WordiestBottomBar(palette: model.settings.palette) {
                    Button("Shuffle") { model.scene.shuffle() }
                        .buttonStyle(WordiestCapsuleButtonStyle(palette: model.settings.palette))

                    Button("Reset") {}
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                                didLongPressReset = true
                                model.scene.resetWords(clearOnlyInvalid: true)
                            }
                        )
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                if didLongPressReset {
                                    didLongPressReset = false
                                    return
                                }
                                model.scene.resetWords(clearOnlyInvalid: false)
                            }
                        )
                        .buttonStyle(WordiestCapsuleButtonStyle(palette: model.settings.palette))

                    Button(model.scene.isReview ? "OK" : "Submit") {
                        if model.scene.isReview {
                            model.returnToScoreFromMatchReview()
                            return
                        }

                        let message = SubmissionWarning.message(validWordCount: model.scene.currentValidWordCount())
                        if let message {
                            submitWarningMessage = message
                        } else {
                            model.handleConfirmedSubmission()
                        }
                    }
                    .buttonStyle(WordiestCapsuleButtonStyle(palette: model.settings.palette))

                    WordiestMenu(
                        model: model,
                        onBack: {
                            if model.scene.isReview, model.matchReviewContext != nil {
                                model.returnToScoreFromMatchReview()
                                return
                            }
                            if model.scene.hasInProgressMove && !model.scene.isReview {
                                isConfirmingLeave = true
                                return
                            }
                            model.returnToSplash()
                        }
                    )
                    .frame(width: 52)
                    .buttonStyle(WordiestCapsuleButtonStyle(palette: model.settings.palette))
                }
                .onPreferenceChange(WordiestHeightPreferenceKey.self) { newHeight in
                    if abs(bottomBarHeight - newHeight) > 0.5 {
                        bottomBarHeight = newHeight
                        updateSceneInsets(proxy: proxy)
                    }
                }

                if model.scene.isReview {
                    VStack {
                        Text(MatchStrings.reviewBanner)
                            .font(.system(size: 18))
                            .foregroundStyle(model.settings.palette.foreground)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(model.settings.palette.faded)
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                }
            }
        }
        .tint(model.settings.palette.foreground)
        .alert(
            "Wiktionary",
            isPresented: Binding(
                get: { wiktionaryWord != nil },
                set: { if !$0 { wiktionaryWord = nil } }
            ),
            presenting: wiktionaryWord
        ) { word in
            Button("Cancel", role: .cancel) {}
            Button("Search") { Wiktionary.open(lookupWord: word) }
        } message: { word in
            Text("Search '\(word)' in Wiktionary?")
        }
        .alert(
            "Confirm",
            isPresented: Binding(
                get: { submitWarningMessage != nil },
                set: { if !$0 { submitWarningMessage = nil } }
            ),
            presenting: submitWarningMessage
        ) { _ in
            Button("Cancel", role: .cancel) {}
            Button("Submit") {
                submitWarningMessage = nil
                model.handleConfirmedSubmission()
            }
        } message: { message in
            Text(message)
        }
        .alert("Confirm", isPresented: $isConfirmingLeave) {
            Button("No", role: .cancel) {}
            Button("Yes") { model.returnToSplash() }
        } message: {
            Text("Leave game in progress?")
        }
    }

    private func updateSceneInsets(proxy: GeometryProxy) {
        let safe = proxy.safeAreaInsets
        model.scene.safeAreaInsetsOverride = UIEdgeInsets(
            top: safe.top,
            left: safe.leading,
            bottom: safe.bottom + bottomBarHeight,
            right: safe.trailing
        )
    }
}
