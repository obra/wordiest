import SwiftUI
import WordiestCore

struct DictionaryLookupView: View {
    var definitions: Definitions
    var palette: ColorPalette

    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var definition: Definitions.Definition?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Word", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { lookup() }

                HStack {
                    Button("Lookup") { lookup() }
                        .buttonStyle(.borderedProminent)
                    Button("Close") { dismiss() }
                        .buttonStyle(.bordered)
                }

                if let definition {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(definition.word) • \(definition.partOfSpeech)")
                            .font(.headline)
                        if let see = definition.seeWord {
                            Text("See \(see)")
                                .font(.subheadline)
                                .foregroundStyle(palette.foreground.opacity(0.75))
                        }
                        Text(definition.definition)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 12)
                } else if let message {
                    Text(message)
                        .foregroundStyle(palette.foreground.opacity(0.75))
                        .padding(.top, 12)
                } else {
                    Spacer()
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(palette.background)
            .navigationTitle("Dictionary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func lookup() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            definition = nil
            message = "Enter a word."
            return
        }

        do {
            definition = try definitions.definition(for: trimmed)
            if definition == nil {
                message = "No definition found."
            } else {
                message = nil
            }
        } catch {
            definition = nil
            message = "Lookup failed."
        }
    }
}

