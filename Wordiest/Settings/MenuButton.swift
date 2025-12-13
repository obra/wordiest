import SwiftUI

struct MenuButton: View {
    @ObservedObject var model: AppModel
    @State private var isPresentingMenu = false

    var body: some View {
        Button("Menu") { isPresentingMenu = true }
            .buttonStyle(.bordered)
            .sheet(isPresented: $isPresentingMenu) {
                MenuView(model: model)
            }
    }
}

