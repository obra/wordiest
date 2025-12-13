import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var scene = GameScene(size: .zero)

    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.configure(size: proxy.size)
                }
                .onChange(of: proxy.size) { _, newSize in
                    scene.configure(size: newSize)
                }
        }
    }
}
