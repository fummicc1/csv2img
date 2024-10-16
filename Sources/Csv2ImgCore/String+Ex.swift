import Foundation

#if canImport(AppKit)
    import AppKit
    typealias Font = NSFont
#elseif canImport(UIKit)
    import UIKit
    typealias Font = UIFont
#endif

extension String {
    func getSize(
        fontSize: Double
    ) -> CGSize {
        (self as NSString)
            .size(
                withAttributes: [
                    .font: Font.systemFont(
                        ofSize: fontSize,
                        weight: .bold
                    )
                ]
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
