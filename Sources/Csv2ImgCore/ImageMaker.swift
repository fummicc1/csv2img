import CoreGraphics
import CoreText
import Foundation

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

public enum ImageMakingError: Error {
    /// Failed to get current `CGContext`
    case noContextAvailable
    case failedCreateImage(
        CGContext
    )
    case underlying(
        Error
    )
}

/// No overview available
protocol ImageMakerType: Maker {
    var latestOutput: CGImage? {
        get
    }
}

/// `ImageMarker` generate png-image from ``Csv``.
final class ImageMaker: ImageMakerType {

    typealias Exportable = CGImage

    init(
        maximumRowCount: Int?,
        fontSize: Double
    ) {
        self.maximumRowCount = maximumRowCount
        self.fontSize = fontSize
    }

    var maximumRowCount: Int?

    var fontSize: Double

    var latestOutput: CGImage?

    func set(
        fontSize size: Double
    ) {
        self.fontSize = size
    }

    /// generate png-image data from ``Csv``.
    internal func make(
        columns: [Csv.Column],
        rows: [Csv.Row],
        progress: @escaping (
            Double
        ) -> Void
    ) throws -> CGImage {
        let representation = try build(columns: columns, rows: rows, progress: progress)
        guard
            let context = CGContext(
                data: nil,
                width: representation.width,
                height: representation.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw ImageMakingError.noContextAvailable
        }
        guard let image = ImageRenderer().render(context: context, representation) else {
            throw ImageMakingError.failedCreateImage(context)
        }
        return image
    }

    internal func build(
        columns: [Csv.Column],
        rows: [Csv.Row],
        progress: @escaping (
            Double
        ) -> Void
    ) throws -> CsvImageRepresentation {

        let length = min(
            maximumRowCount ?? rows.count,
            rows.count
        )
        let rows = rows[..<length].map {
            $0
        }

        let horizontalSpace = 8
        let verticalSpace = 12
        let textSizeList =
            rows
            .flatMap({
                $0.values
            })
            .map({
                $0.getSize(
                    fontSize: fontSize
                )
            })
            + columns
            .map({
                $0.name
            })
            .map({
                $0.getSize(
                    fontSize: fontSize
                )
            })

        let longestHeight = textSizeList.map({
            $0.height
        }).sorted().reversed()[0]
        let longestWidth = textSizeList.map({
            $0.width
        }).sorted().reversed()[0]
        let width =
            (Int(
                longestWidth
            ) + horizontalSpace) * columns.count
        let height =
            (rows.count + 1)
            * (Int(
                longestHeight
            ) + verticalSpace)

        let backgroundColor = CGColor(red: 250 / 255, green: 250 / 255, blue: 250 / 255, alpha: 1)

        let columnWidth = width / columns.count
        let rowHeight = height / (rows.count + 1)

        var columnRepresentations: [CsvImageRepresentation.ColumnRepresentation] = []
        var rowRepresentations: [CsvImageRepresentation.RowRepresentation] = []

        let completeCount: Double = Double(rows.count + columns.count)
        var completeFraction: Double = 0

        for (i, column) in columns.enumerated() {
            let size = column.name.getSize(fontSize: fontSize)
            let originX = i * columnWidth + columnWidth / 2 - Int(size.width) / 2
            let originY = height - Int(size.height) / 2 - rowHeight / 2

            columnRepresentations.append(
                CsvImageRepresentation.ColumnRepresentation(
                    name: column.name,
                    style: column.style,
                    frame: CGRect(
                        x: originX,
                        y: originY,
                        width: columnWidth,
                        height: rowHeight
                    )
                )
            )

            completeFraction += 1
            progress(completeFraction / completeCount)
        }

        for (i, row) in rows.enumerated() {
            var rowFrames: [CGRect] = []
            for (j, item) in row.values.enumerated() {
                if columns.count <= j { continue }

                let size = item.getSize(fontSize: fontSize)
                let originX = j * columnWidth + columnWidth / 2 - Int(size.width) / 2
                let originY = height - (i + 2) * rowHeight + Int(size.height) / 2

                rowFrames.append(
                    CGRect(
                        x: originX,
                        y: originY,
                        width: columnWidth,
                        height: rowHeight
                    )
                )
            }

            rowRepresentations.append(
                CsvImageRepresentation.RowRepresentation(
                    values: row.values,
                    frames: rowFrames
                )
            )

            completeFraction += 1
            progress(completeFraction / completeCount)
        }

        return CsvImageRepresentation(
            width: width,
            height: height,
            backgroundColor: backgroundColor,
            fontSize: CGFloat(fontSize),
            columns: columnRepresentations,
            rows: rowRepresentations
        )
    }
}
