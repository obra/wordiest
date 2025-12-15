import SwiftUI

struct PalettePickerView: View {
    @ObservedObject var settings: AppSettings

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let palette = settings.palette
        NavigationStack {
            List {
                ForEach(AppSettings.ThemeMode.allCases, id: \.rawValue) { mode in
                    Button {
                        settings.themeMode = mode
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(mode.title)
                                .foregroundStyle(palette.foreground)

                            Spacer()

                            if settings.themeMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(palette.foreground)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)
            .navigationTitle("Appearance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(palette.foreground)
    }
}
