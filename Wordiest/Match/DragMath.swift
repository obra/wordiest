import CoreGraphics

enum DragMath {
    static func draggedCenterX(touchX: CGFloat, touchOffsetX: CGFloat) -> CGFloat {
        touchX - touchOffsetX
    }
}

