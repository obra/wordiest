import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene = GameScene(size: .zero)

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
                    Button("Reset") { scene.resetWords() }
                    Button("Submit") { scene.submit() }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 24)
            }
        }
    }
}
