import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene = GameScene(size: .zero)
    @State private var didLongPressReset = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .onAppear {
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
                    Button("Submit") { scene.submit() }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 24)
            }
        }
    }
}
