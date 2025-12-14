import SpriteKit
import SwiftUI

struct MatchView: View {
    @ObservedObject var model: AppModel

    @State private var didLongPressReset = false
    @State private var wiktionaryWord: String?
    @State private var submitWarningMessage: String?
    @State private var isConfirmingLeave = false
    @State private var isPresentingMenu = false

    var body: some View {
        GeometryReader { proxy in
            let sceneSize = CGSize(
                width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            )
            ZStack(alignment: .bottom) {
                SpriteView(scene: model.scene)
                    .ignoresSafeArea()
                    .onAppear {
                        let safe = proxy.safeAreaInsets
                        let extraTop: CGFloat = model.scene.isReview ? 50 : 0
                        model.scene.safeAreaInsetsOverride = UIEdgeInsets(top: safe.top + extraTop, left: safe.leading, bottom: safe.bottom, right: safe.trailing)
                        model.scene.onRequestOpenWiktionary = { word in
                            wiktionaryWord = word
                        }
                        model.configureSceneIfReady(size: sceneSize)
                        model.applySettingsToScene()
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        model.configureSceneIfReady(
                            size: CGSize(
                                width: newSize.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                                height: newSize.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                            )
                        )
                    }
                    .onChange(of: proxy.safeAreaInsets) { _, newInsets in
                        let extraTop: CGFloat = model.scene.isReview ? 50 : 0
                        model.scene.safeAreaInsetsOverride = UIEdgeInsets(top: newInsets.top + extraTop, left: newInsets.leading, bottom: newInsets.bottom, right: newInsets.trailing)
                        model.configureSceneIfReady(
                            size: CGSize(
                                width: proxy.size.width + newInsets.leading + newInsets.trailing,
                                height: proxy.size.height + newInsets.top + newInsets.bottom
                            )
                        )
                    }
                    .onChange(of: model.settings.soundEnabled) { _, _ in
                        model.applySettingsToScene()
                    }
                    .onChange(of: model.settings.colorPaletteIndex) { _, _ in
                        model.applySettingsToScene()
                    }

                HStack(spacing: 1) {
                    Button("Shuffle") { model.scene.shuffle() }
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
                    Button {
                        isPresentingMenu = true
                    } label: {
                        Image(systemName: "ellipsis.vertical")
                    }
                }
                .buttonStyle(WordiestBarButtonStyle(palette: model.settings.palette))
                .padding(.top, 1)
                .frame(height: 50)
                .background(model.settings.palette.faded)

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

                OverflowMenuOverlay(
                    model: model,
                    isPresented: $isPresentingMenu,
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
}
