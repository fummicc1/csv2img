#if os(macOS)
import AppKit
typealias Image = NSImage
typealias Color = NSColor
typealias Rect = NSRect
#elseif os(iOS)
import UIKit
typealias Image = UIImage
typealias Color = UIColor
typealias Rect = CGRect
#endif

import Foundation
import CoreGraphics
import CoreText


/// No overview available
protocol ImageMakerType {
    func make(csv: Csv) -> CGImage
    func setFontSize(_ size: CGFloat)
}

/// `ImageMarker` generate png-image from ``Csv``.
class ImageMaker: ImageMakerType {
    init(
        fontSize: CGFloat
    ) {
        self.fontSize = fontSize
    }

    var fontSize: CGFloat

    func setFontSize(_ size: CGFloat) {
        self.fontSize = size
    }

    /// generate png-image data from ``Csv``.
    func make(
        csv: Csv
    ) -> CGImage {

        let horizontalSpace = 8
        let verticalSpace = 12
        let textSizeList =
        csv.rows
            .flatMap({ $0.values })
            .map({ $0.getSize(fontSize: fontSize) })
        +
        csv.columnNames
            .map({ $0.value })
            .map({ $0.getSize(fontSize: fontSize) })

        let longestHeight = textSizeList.map({ $0.height }).sorted().reversed()[0]
        let longestWidth = textSizeList.map({ $0.width }).sorted().reversed()[0]
        let width = (Int(longestWidth) + horizontalSpace) * csv.columnNames.count
        let height = (csv.rows.count + 1) * (Int(longestHeight) + verticalSpace)

        #if os(macOS)
        let canvas = NSImage(
            size: NSSize(width: width, height: height)
        )
        canvas.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            fatalError()
        }
        #elseif os(iOS)
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError()
        }
        #endif

        context.setFillColor(CGColor(
            red: 250/255,
            green: 250/255,
            blue: 250/255,
            alpha: 1)
        )
        context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))

        context.setLineWidth(1)
        #if os(macOS)
        context.setStrokeColor(Color.separatorColor.cgColor)
        #elseif os(iOS)
        context.setStrokeColor(Color.separator.cgColor)
        #endif
        context.setFillColor(CGColor(
            red: 22/255,
            green: 22/255,
            blue: 22/255,
            alpha: 1
        ))

        let columnCount = csv.columnNames.count
        let rowCount = csv.rows.count + 1
        let rowHeight = Int(height) / rowCount
        let columnWidth = Int(width) / columnCount


        for i in 0..<columnCount {
            context.move(
                to: CGPoint(
                    x: i * columnWidth,
                    y: 0
                )
            )
            context.addLine(
                to: CGPoint(
                    x: i * columnWidth,
                    y: Int(height)
                )
            )
        }
        for j in 0..<rowCount {
            context.move(
                to: CGPoint(
                    x: 0,
                    y: j * rowHeight
                )
            )
            context.addLine(
                to: CGPoint(
                    x: Int(width),
                    y: j * rowHeight
                )
            )
        }

        for (i, column) in csv.columnNames.enumerated() {
            let str = NSAttributedString(
                string: column.value,
                attributes: [
                    .font: Font.systemFont(ofSize: fontSize, weight: .bold)
                ]
            )
            let size = str.string.getSize(fontSize: fontSize)
            let originX = i * columnWidth + columnWidth / 2 - Int(size.width) / 2
            let originY = height - Int(size.height) / 2 - rowHeight / 2
            context.saveGState()
            str._draw(
                at: Rect(
                    origin: CGPoint(x: originX, y: originY),
                    size: CGSize(width: columnWidth, height: rowHeight)
                )
            )
            context.restoreGState()
        }

        for (var i, row) in csv.rows.enumerated() {
            i += 1
            for (j, item) in row.values.enumerated() {
                let str = NSAttributedString(
                    string: item,
                    attributes: [
                        .font: Font.systemFont(ofSize: fontSize)
                    ]
                )
                let size = str.string.getSize(fontSize: fontSize)
                let originX = j * columnWidth + columnWidth / 2 - Int(size.width) / 2
                let originY = height - (i+1) * rowHeight + Int(size.height) / 2
                context.saveGState()
                str._draw(
                    at: Rect(
                        origin: CGPoint(x: originX, y: originY),
                        size: size
                    )
                )
                context.restoreGState()
            }
        }
        context.drawPath(using: .stroke)
        guard let image = context.makeImage() else {
            fatalError()
        }
        #if os(macOS)
        canvas.unlockFocus()
        #endif

        return image
    }
}

