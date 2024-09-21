import CoreGraphics
import Foundation

#if canImport(AppKit)
    import AppKit
    extension CGImage {
        public func convertToData() -> Data? {
            let rep = NSBitmapImageRep(
                cgImage: self
            )
            return rep.representation(
                using: .png,
                properties: [:]
            )
        }
    }
#elseif canImport(UIKit)
    import UIKit
    extension CGImage {
        public func convertToData() -> Data? {
            let img = UIImage(
                cgImage: self
            )
            return img.pngData()
        }
    }
#endif
