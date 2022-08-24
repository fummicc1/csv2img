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


public enum ImageMakingError: Error {
    /// Failed to get current `CGContext`
    case noContextAvailable
    case failedCreateImage(CGContext)
    case underlying(Error)
}

/// No overview available
protocol ImageMakerType: Maker {
    var latestOutput: CGImage? { get }
    func make(columns: [Csv.ColumnName], rows: [Csv.Row], progress: @escaping (Double) -> Void) throws -> CGImage
    func setFontSize(_ size: CGFloat)
}

/// `ImageMarker` generate png-image from ``Csv``.
class ImageMaker: ImageMakerType {

    typealias Exportable = CGImage

    init(
        maximumRowCount: Int?,
        fontSize: CGFloat
    ) {
        self.maximumRowCount = maximumRowCount
        self.fontSize = fontSize
    }

    var maximumRowCount: Int?

    var fontSize: CGFloat

    var latestOutput: CGImage?

    func setFontSize(_ size: CGFloat) {
        self.fontSize = size
    }

    /// generate png-image data from ``Csv``.
    func make(
        columns: [Csv.ColumnName],
        rows: [Csv.Row],
        progress: @escaping (Double) -> Void
    ) throws -> CGImage {

        let length = min(maximumRowCount ?? rows.count, rows.count)
        let rows = rows[..<length].map { $0 }

        let horizontalSpace = 8
        let verticalSpace = 12
        let textSizeList =
        rows
            .flatMap({ $0.values })
            .map({ $0.getSize(fontSize: fontSize) })
        +
        columns
            .map({ $0.value })
            .map({ $0.getSize(fontSize: fontSize) })

        let longestHeight = textSizeList.map({ $0.height }).sorted().reversed()[0]
        let longestWidth = textSizeList.map({ $0.width }).sorted().reversed()[0]
        let width = (Int(longestWidth) + horizontalSpace) * columns.count
        let height = (rows.count + 1) * (Int(longestHeight) + verticalSpace)

        #if os(macOS)
        let canvas = NSImage(
            size: NSSize(width: width, height: height)
        )
        canvas.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            throw ImageMakingError.noContextAvailable
        }
        #elseif os(iOS)
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        guard let context = UIGraphicsGetCurrentContext() else {
            throw ImageMakingError.noContextAvailable
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

        let columnCount = columns.count
        let rowCount = rows.count + 1
        let rowHeight = Int(height) / rowCount
        let columnWidth = Int(width) / columnCount

        let completeCount: Double = Double(rowCount + columnCount)
        var completeFraction: Double = 0

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

        for (i, column) in columns.enumerated() {
            let str = NSAttributedString(
                string: column.value,
                attributes: [
                    .font: Font.systemFont(ofSize: fontSize, weight: .bold)
                ]
            )
            let size = str.string.getSize(fontSize: fontSize)
            let originX = i * columnWidth + columnWidth / 2 - Int(size.width) / 2
            #if os(macOS)
            let originY = height - Int(size.height) / 2 - rowHeight / 2
            #elseif os(iOS)
            let originY = Int(size.height) / 2
            #endif
            context.saveGState()
            str._draw(
                at: Rect(
                    origin: CGPoint(x: originX, y: originY),
                    size: CGSize(width: columnWidth, height: rowHeight)
                )
            )
            context.restoreGState()
            completeFraction += 1
            progress(completeFraction / completeCount)
        }

        for (var i, row) in rows.enumerated() {
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
#if os(macOS)
                let originY = height - (i+1) * rowHeight + Int(size.height) / 2
#elseif os(iOS)
                let originY = i * rowHeight + rowHeight / 2 - Int(size.height) / 2
#endif
                context.saveGState()
                str._draw(
                    at: Rect(
                        origin: CGPoint(x: originX, y: originY),
                        size: size
                    )
                )
                context.restoreGState()
            }
            completeFraction += 1
            progress(completeFraction / completeCount)
        }
        context.drawPath(using: .stroke)
        guard let image = context.makeImage() else {
            throw ImageMakingError.failedCreateImage(context)
        }
        #if os(macOS)
        canvas.unlockFocus()
        #elseif os(iOS)
        UIGraphicsEndImageContext()
        #endif

        self.latestOutput = image

        return image
    }
}

