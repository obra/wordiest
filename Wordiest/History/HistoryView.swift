import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let palette = model.settings.palette
        VStack(spacing: 12) {
            HStack {
                Button("Back") { model.returnToSplash() }
                    .buttonStyle(.bordered)
                Spacer()
                MenuButton(model: model)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            if model.historyStore.entries.isEmpty {
                Spacer()
                Text("No history yet.")
                    .foregroundStyle(palette.foreground)
                Spacer()
            } else {
                List {
                    ForEach(model.historyStore.entries) { entry in
                        Text("\(entry.matchId) (\(entry.score) pts)")
                            .foregroundStyle(palette.foreground)
                    }
                    .onDelete { offsets in
                        for idx in offsets {
                            let id = model.historyStore.entries[idx].id
                            model.historyStore.delete(id: id)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }
}
