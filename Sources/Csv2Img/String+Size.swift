#if canImport(AppKit)
import AppKit
import Foundation

extension String {
    func getSize(fontSize: CGFloat) -> CGSize {
        (self as NSString)
            .size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize)])
    }
}
#endif
