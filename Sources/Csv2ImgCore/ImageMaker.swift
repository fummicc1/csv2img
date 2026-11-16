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

    private func createContext(
        width: Int,
        height: Int
    ) throws -> CGContext {

        #if os(macOS)
            let canvas = NSImage(
                size: NSSize(
                    width: width,
                    height: height
                )
            )
            canvas.lockFocus()
            guard let context = NSGraphicsContext.current?.cgContext else {
                throw ImageMakingError.noContextAvailable
            }
        #elseif os(iOS)
        UIGraphicsBeginImageContextWithOptions(
                CGSize(
                    width: width,
                    height: height
                ),
                true,
                0
            )
            guard let context = UIGraphicsGetCurrentContext() else {
                throw ImageMakingError.noContextAvailable
            }
        #endif

        defer {
            #if os(macOS)
                canvas.unlockFocus()
            #elseif os(iOS)
                UIGraphicsEndImageContext()
            #endif
        }

        return context
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
        let context = try createContext(width: representation.width, height: representation.height)

        let renderer = ImageRenderer()
        let image = renderer.render(context: context, representation)
        guard let image = image else {
            throw ImageMakingError.failedCreateImage(context)
        }

        self.latestOutput = image
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

        let backgroundColor = CGColor(red: 250 / 255, green: 250 / 255, blue: 250 / 255, alpha: 1)

        let headerSizes = columns.map { $0.name.getSize(fontSize: fontSize) }
        let cellSizes = rows.map { row in
            row.values.map { $0.getSize(fontSize: fontSize) }
        }

        let columnWidths = calculateColumnWidths(headerSizes: headerSizes, cellSizes: cellSizes)
        let width = columnWidths.reduce(0, +) + (columns.count + 1) * horizontalSpace

        let rowHeights = calculateRowHeights(
            headerSizes: headerSizes, cellSizes: cellSizes, columnWidths: columnWidths)
        let height = rowHeights.reduce(0, +) + (rows.count + 2) * verticalSpace

        var xOffsets: [Int] = []
        xOffsets.reserveCapacity(columnWidths.count)
        var nextXOffset = horizontalSpace
        for columnWidth in columnWidths {
            xOffsets.append(nextXOffset)
            nextXOffset += columnWidth + horizontalSpace
        }

        var rowRepresentations: [CsvImageRepresentation.RowRepresentation] = []
        rowRepresentations.reserveCapacity(rows.count)

        let reporter = ProgressReporter(total: rows.count, progress: progress)

        var yOffset = verticalSpace
        let columnRepresentations = columns.enumerated().map { (i, column) in
            CsvImageRepresentation.ColumnRepresentation(
                name: column.name,
                style: column.style,
                frame: CGRect(
                    x: xOffsets[i], y: yOffset, width: columnWidths[i], height: rowHeights[0])
            )
        }
        yOffset += rowHeights[0] + verticalSpace

        for (i, row) in rows.enumerated() {
            let rowFrames = (0..<min(row.values.count, columns.count)).map { j in
                CGRect(
                    x: xOffsets[j], y: yOffset, width: columnWidths[j], height: rowHeights[i + 1])
            }
            rowRepresentations.append(
                CsvImageRepresentation.RowRepresentation(
                    values: row.values,
                    frames: rowFrames
                )
            )
            yOffset += rowHeights[i + 1] + verticalSpace

            reporter.advance()
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

    private func calculateColumnWidths(headerSizes: [CGSize], cellSizes: [[CGSize]]) -> [Int] {
        var maxWidths = headerSizes.map(\.width)
        for sizes in cellSizes {
            for (index, size) in sizes.prefix(maxWidths.count).enumerated() {
                maxWidths[index] = max(maxWidths[index], size.width)
            }
        }
        return maxWidths.map { Int($0) + 20 }
    }

    private func calculateRowHeights(
        headerSizes: [CGSize], cellSizes: [[CGSize]], columnWidths: [Int]
    ) -> [Int] {
        let headerHeight = Int(headerSizes.map(\.height).max() ?? 0) + 10

        let contentHeights = cellSizes.map { sizes in
            let maxHeight =
                sizes.enumerated().map { (index, size) -> CGFloat in
                    guard index < columnWidths.count else { return 0 }
                    let lines = ceil(size.width / CGFloat(columnWidths[index]))
                    return size.height * lines
                }.max() ?? 0
            return Int(maxHeight) + 10
        }

        return [headerHeight] + contentHeights
    }
}
