import SpriteKit
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var scene = GameScene(size: .zero)
    @State private var didLongPressReset = false
    @State private var wiktionaryWord: String?
    @State private var submitWarningMessage: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .onAppear {
                        scene.onRequestOpenWiktionary = { word in
                            wiktionaryWord = word
                        }
                        scene.configure(size: proxy.size)
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        scene.configure(size: newSize)
                    }

                HStack(spacing: 12) {
                    Button("Shuffle") { scene.shuffle() }
                    Button("Reset") {}
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                                didLongPressReset = true
                                scene.resetWords(clearOnlyInvalid: true)
                            }
                        )
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                if didLongPressReset {
                                    didLongPressReset = false
                                    return
                                }
                                scene.resetWords(clearOnlyInvalid: false)
                            }
                        )
                    Button(scene.isReview ? "OK" : "Submit") {
                        if scene.isReview {
                            scene.submit()
                            return
                        }

                        let message = SubmissionWarning.message(validWordCount: scene.currentValidWordCount())
                        if let message {
                            submitWarningMessage = message
                        } else {
                            scene.submit()
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
                scene.submit()
            }
        } message: { message in
            Text(message)
        }
    }
}
