import CoreGraphics
import Foundation

public protocol Drawable {
    func convertToData() -> Data?
}

#if canImport(AppKit)
import AppKit
extension CGImage: Drawable {
    public func convertToData() -> Data? {
        let rep = NSBitmapImageRep(cgImage: self)
        return rep.representation(using: .png, properties: [:])
    }
}
#elseif canImport(UIKit)
import UIKit
extension CGImage: Drawable {
    public func convertToData() -> Data? {
        let img = UIImage(cgImage: self)
        return img.pngData()
    }
}
#endif
