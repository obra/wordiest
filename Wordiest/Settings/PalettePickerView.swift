import SwiftUI

struct PalettePickerView: View {
    @ObservedObject var settings: AppSettings

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(1...6, id: \.self) { index in
                    let palette = ColorPalette.palette(index: index)
                    Button {
                        settings.colorPaletteIndex = index
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(palette.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(palette.foreground, lineWidth: 2)
                                )
                                .frame(width: 44, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(label(for: index))
                                    .foregroundStyle(palette.foreground)
                                Text("#\(index)")
                                    .font(.footnote)
                                    .foregroundStyle(palette.faded)
                            }

                            Spacer()

                            if settings.colorPaletteIndex == index {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(palette.foreground)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Colors")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func label(for index: Int) -> String {
        switch index {
        case 1: return "Light"
        case 2: return "Dark"
        case 3: return "Gold"
        case 4: return "Purple"
        case 5: return "Orange"
        case 6: return "Black"
        default: return "Palette"
        }
    }
}

