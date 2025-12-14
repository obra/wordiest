import SwiftUI

struct WordiestCapsuleButtonStyle: ButtonStyle {
    var palette: ColorPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(palette.foreground)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(palette.faded.opacity(configuration.isPressed ? 0.55 : 0.35))
            )
            .overlay(
                Capsule()
                    .stroke(palette.faded.opacity(0.75), lineWidth: 1)
            )
    }
}

