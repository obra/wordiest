import SwiftUI

struct ShareScreenshotView: View {
    @ObservedObject var model: AppModel

    @Environment(\.dismiss) private var dismiss

    @State private var includeWords = true
    @State private var includeScore = true
    @State private var image: UIImage?
    @State private var isPresentingShare = false

    var body: some View {
        let palette = model.settings.palette
        NavigationStack {
            Form {
                Section("Include") {
                    Toggle("Include my words", isOn: $includeWords)
                    Toggle("Include my score", isOn: $includeScore)
                }

                Section {
                    Button("Capture screenshot") {
                        image = ScreenshotCapture.capture()
                    }
                    Button("Share") {
                        if image == nil {
                            image = ScreenshotCapture.capture()
                        }
                        isPresentingShare = true
                    }
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
            .onAppear {
                image = ScreenshotCapture.capture()
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
