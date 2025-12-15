import SwiftUI

struct ShareScreenshotView: View {
    @ObservedObject var model: AppModel
    var initialImage: UIImage?

    @Environment(\.dismiss) private var dismiss

    @State private var includeWords = true
    @State private var includeScore = true
    @State private var image: UIImage?
    @State private var isPresentingShare = false

    init(model: AppModel, initialImage: UIImage? = nil) {
        self.model = model
        self.initialImage = initialImage
        _image = State(initialValue: initialImage)
    }

    var body: some View {
        let palette = model.settings.palette
        NavigationStack {
            Form {
                Section("Include") {
                    Toggle("Include my words", isOn: $includeWords)
                    Toggle("Include my score", isOn: $includeScore)
                }

                Section {
                    Button("Share") {
                        isPresentingShare = true
                    }
                    .disabled(image == nil)
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)
            .navigationTitle("Share screenshot")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $isPresentingShare) {
                ShareSheet(activityItems: shareItems())
            }
        }
    }

    private func shareItems() -> [Any] {
        var items: [Any] = []
        if includeWords || includeScore {
            let words = model.scene.currentWords()
            let score = model.scene.currentScoreValue()

            var parts: [String] = []
            if includeWords {
                let joined = [words.word1, words.word2].filter { !$0.isEmpty }.joined(separator: " + ")
                if !joined.isEmpty { parts.append(joined.uppercased()) }
            }
            if includeScore {
                parts.append(MatchStrings.totalScore(score))
            }
            if !parts.isEmpty {
                items.append(parts.joined(separator: " — "))
            }
        }

        if let image {
            items.append(image)
        }
        return items
    }
}
