import SwiftUI

struct WordiestBottomBar<Content: View>: View {
    var palette: ColorPalette
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(palette.faded.opacity(0.5))
                .frame(height: 1)
            HStack(spacing: 12) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(palette.background.opacity(0.98))
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: WordiestHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
    }
}
