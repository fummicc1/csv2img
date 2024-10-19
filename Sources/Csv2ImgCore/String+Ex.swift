import Foundation
import CoreText

extension String {
    func getSize(
        fontSize: Double
    ) -> CGSize {
        // Calculate the size of the string using CoreText
        let font = getFont(ofSize: fontSize)
        let attrString = NSAttributedString(
            string: self,
            attributes: [
                .font: font
            ])
        let size = attrString.size()
        return CGSize(
            width: Int(size.width),
            height: Int(size.height)
        )
    }
    
    func getFont(ofSize fontSize: CGFloat) -> CTFont {
        CTFontCreateWithName(
            "San Francisco" as CFString,
            fontSize,
            nil
        )
    }
}

extension NSAttributedString {
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
