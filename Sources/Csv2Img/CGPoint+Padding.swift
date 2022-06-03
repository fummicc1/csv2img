import CoreGraphics

extension CGPoint {
    func withPadding(x paddingX: CGFloat, y paddingY: CGFloat) -> CGPoint {
        CGPoint(
            x: x + paddingX,
            y: y + paddingY
        )
    }
}
