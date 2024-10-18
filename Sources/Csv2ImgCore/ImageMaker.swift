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
            UIGraphicsBeginImageContext(
                CGSize(
                    width: width,
                    height: height
                )
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

        let columnWidths = calculateColumnWidths(columns: columns, rows: rows)
        let width = columnWidths.reduce(0, +) + (columns.count + 1) * horizontalSpace

        let rowHeights = calculateRowHeights(
            columns: columns, rows: rows, columnWidths: columnWidths)
        let height = rowHeights.reduce(0, +) + (rows.count + 2) * verticalSpace

        var columnRepresentations: [CsvImageRepresentation.ColumnRepresentation] = []
        var rowRepresentations: [CsvImageRepresentation.RowRepresentation] = []

        let completeCount: Double = Double(rows.count + columns.count)
        var completeFraction: Double = 0

        var yOffset = verticalSpace
        // ヘッダー行の描画
        for (i, column) in columns.enumerated() {
            let xOffset = columnWidths[0..<i].reduce(0, +) + (i + 1) * horizontalSpace
            let frame = CGRect(
                x: xOffset, y: yOffset, width: columnWidths[i], height: rowHeights[0])
            columnRepresentations.append(
                CsvImageRepresentation.ColumnRepresentation(
                    name: column.name,
                    style: column.style,
                    frame: frame
                )
            )
        }
        yOffset += rowHeights[0] + verticalSpace

        // データ行の描画
        for (i, row) in rows.enumerated() {
            var rowFrames: [CGRect] = []
            for (j, item) in row.values.enumerated() {
                if columns.count <= j { continue }
                let xOffset = columnWidths[0..<j].reduce(0, +) + (j + 1) * horizontalSpace
                let frame = CGRect(
                    x: xOffset, y: yOffset, width: columnWidths[j], height: rowHeights[i + 1])
                rowFrames.append(frame)
            }
            rowRepresentations.append(
                CsvImageRepresentation.RowRepresentation(
                    values: row.values,
                    frames: rowFrames
                )
            )
            yOffset += rowHeights[i + 1] + verticalSpace

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

    private func calculateColumnWidths(columns: [Csv.Column], rows: [Csv.Row]) -> [Int] {
        return columns.enumerated().map { (index, column) in
            let headerWidth = column.name.getSize(fontSize: fontSize).width
            let maxContentWidth =
                rows.map { row in
                    row.values.count > index
                        ? row.values[index].getSize(fontSize: fontSize).width : 0
                }.max() ?? 0
            return Int(max(headerWidth, maxContentWidth)) + 20  // 20はパディング
        }
    }

    private func calculateRowHeights(columns: [Csv.Column], rows: [Csv.Row], columnWidths: [Int])
        -> [Int]
    {
        let headerHeight =
            Int(columns.map { $0.name.getSize(fontSize: fontSize).height }.max() ?? 0) + 10

        let contentHeights = rows.map { row in
            let maxHeight =
                row.values.enumerated().map { (index, value) in
                    if index < columnWidths.count {
                        let size = value.getSize(fontSize: fontSize)
                        let lines = ceil(size.width / CGFloat(columnWidths[index]))
                        return size.height * lines
                    }
                    return 0
                }.max() ?? 0
            return Int(maxHeight) + 10  // 10はパディング
        }

        return [headerHeight] + contentHeights
    }
}
