import SpriteKit
import SwiftUI

struct MatchView: View {
    @ObservedObject var model: AppModel

    @State private var didLongPressReset = false
    @State private var wiktionaryWord: String?
    @State private var submitWarningMessage: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                SpriteView(scene: model.scene)
                    .ignoresSafeArea()
                    .onAppear {
                        model.scene.onRequestOpenWiktionary = { word in
                            wiktionaryWord = word
                        }
                        model.configureSceneIfReady(size: proxy.size)
                        model.applySettingsToScene()
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        model.configureSceneIfReady(size: newSize)
                    }

                HStack(spacing: 12) {
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
                            model.returnToSplash()
                            return
                        }

                        let message = SubmissionWarning.message(validWordCount: model.scene.currentValidWordCount())
                        if let message {
                            submitWarningMessage = message
                        } else {
                            model.handleConfirmedSubmission()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 24)
            }
        }
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
    }
}

