import Foundation
import CoreText

extension String {
    func getSize(
        fontSize: Double
    ) -> CGSize {
        NSAttributedString(
            string: self,
            attributes: [
                .font: getFont(ofSize: fontSize)
            ]
        ).integralSize()
    }

    func getFont(ofSize fontSize: CGFloat) -> CTFont {
        FontCache.shared.font(ofSize: fontSize)
    }
}

/// Resolving a font by name costs far more than measuring a string, and every cell asks for the same one.
private final class FontCache: @unchecked Sendable {
    static let shared = FontCache()

    private let lock = NSLock()
    private var fonts: [CGFloat: CTFont] = [:]

    func font(ofSize fontSize: CGFloat) -> CTFont {
        lock.lock()
        defer { lock.unlock() }
        if let font = fonts[fontSize] {
            return font
        }
        let font = CTFontCreateWithName(
            "San Francisco" as CFString,
            fontSize,
            nil
        )
        fonts[fontSize] = font
        return font
    }
}

extension NSAttributedString {
    func integralSize() -> CGSize {
        let size = size()
        return CGSize(
            width: Int(size.width),
            height: Int(size.height)
        )
    }

    func _draw(
        at rect: Rect
    ) {
        #if os(macOS)
            draw(
                with: rect
            )
        #elseif os(iOS)
            draw(
                in: rect
            )
        #endif
    }
}
