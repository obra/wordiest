import CoreGraphics

enum WordiestTileStyle {
    // Android reference (v1.188):
    // tile_width = 64dp
    // bonus_height = 80dp
    // tile_corner_radius = 8dp
    // tile_border_width = 4dp
    // tile_letter_text_size = 50sp
    // tile_bonus_text_size = 12sp
    // tile_value_text_size = 12sp
    // tile_top/tile_bottom = 8dp
    static let aspectRatio: CGFloat = 80.0 / 64.0

    static let tileOffsetYRatio: CGFloat = 8.0 / 80.0
    static let bonusInsetXRatio: CGFloat = 1.0 / 4.0

    static let cornerRadiusRatio: CGFloat = 8.0 / 64.0
    static let borderWidthRatio: CGFloat = 4.0 / 64.0

    static let letterFontRatio: CGFloat = 50.0 / 64.0
    static let smallFontRatio: CGFloat = 12.0 / 64.0

    static let padding7dpRatio: CGFloat = 7.0 / 64.0
    static let padding3dpRatio: CGFloat = 3.0 / 64.0
    static let padding6dpRatio: CGFloat = 6.0 / 64.0
    // Baselines are tuned for iOS font metrics so bonus text lands in the same place as Android.
    static let bonusTopBaselineFromTopRatio: CGFloat = 11.0 / 80.0
    static let bonusBottomBaselineFromBottomRatio: CGFloat = 2.0 / 80.0
    static let valueBaselineFromBottomRatio: CGFloat = 15.0 / 80.0

    static func height(forWidth width: CGFloat) -> CGFloat {
        width * aspectRatio
    }
}
