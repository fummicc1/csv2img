import Foundation
import CoreGraphics
import PDFKit

public enum PdfMakingError: Error {
    /// Failed to get/create `CGContext`.
    case noContextAvailabe
    case failedToGeneratePdf
    case emptyRows
    case underlying(Error)
}

/// No overview available
protocol PdfMakerType: Maker {
    var latestOutput: PDFDocument? { get }
    func make(columns: [Csv.Column], rows: [Csv.Row], progress: @escaping (Double) -> Void) throws -> PDFDocument
    func setMetadata(_ metadata: PDFMetadata)
    func setFontSize(_ size: CGFloat)
}

/// ``PdfMaker`` generate pdf from ``Csv`` (Work In Progress).
class PdfMaker: PdfMakerType {

    typealias Exportable = PDFDocument

    init(
        maximumRowCount: Int?,
        fontSize: CGFloat,
        metadata: PDFMetadata
    ) {
        self.maximumRowCount = maximumRowCount
        self.fontSize = fontSize
        self.metadata = metadata
    }

    var maximumRowCount: Int?
    var fontSize: CGFloat
    var metadata: PDFMetadata

    var latestOutput: PDFDocument?

    func setFontSize(_ size: CGFloat) {
        self.fontSize = size
    }


    /// generate png-image data from ``Csv``.
    func make(
        columns: [Csv.Column],
        rows: [Csv.Row],
        progress: @escaping (Double) -> Void
    ) throws -> PDFDocument {
        // NOTE: Anchor is bottom-left.
        let horizontalSpace: CGFloat = 8
        let verticalSpace: CGFloat = 12

        let size = min(maximumRowCount ?? rows.count, rows.count)
        let rows = rows[..<size].map { $0 }

        if rows.isEmpty {
            throw PdfMakingError.emptyRows
        }

        let textSizeList =
        rows
            .flatMap({ $0.values })
            .map({ $0.getSize(fontSize: fontSize) })
        +
        columns
            .map({ $0.name })
            .map({ $0.getSize(fontSize: fontSize) })

        let styles: [Csv.Column.Style] = columns.map(\.style)

        let longestHeight = textSizeList.map({ $0.height }).sorted().reversed()[0]
        let longestWidth = textSizeList.map({ $0.width }).sorted().reversed()[0]

        let rowHeight = longestHeight + verticalSpace
        let columnWidth = longestWidth + horizontalSpace
        let lineWidth: CGFloat = 1

        let width = (longestWidth + horizontalSpace) * CGFloat(columns.count)
        let allRowsHeight = CGFloat(rows.count) * (longestHeight + verticalSpace)

        let maxRowsHeight = min(480, allRowsHeight)

        let totalPageNumber = Int(allRowsHeight / maxRowsHeight)

        let totalHeight = allRowsHeight + CGFloat(totalPageNumber) * rowHeight

        let pageHeight = min(maxRowsHeight + rowHeight, totalHeight)

        var mediaBox = CGRect(
            origin: .zero,
            size: CGSize(
                width: width,
                height: pageHeight
            )
        )

        // Max size on iOS is `2**32 (32bit)`
        let data = CFDataCreateMutable(nil, Int(1 << 32))!
        let consumer = CGDataConsumer(data: data)!
        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &mediaBox,
            nil
        ) else {
            throw PdfMakingError.noContextAvailabe
        }

        // `-1` is due to column space.
        let maxNumberOfRowsInPage: Int = Int(ceil(pageHeight / rowHeight - 1))

        let completeCount: Double = Double(totalPageNumber)
        var completeFraction: Double = 0

        var currentPageNumber: Int = 1
        var startRowIndex: Int = 0
        while currentPageNumber <= totalPageNumber {
            let mediaBoxPerPage = CGRect(
                origin: .zero,
                size: CGSize(
                    width: width,
                    height: pageHeight
                )
            )
            let coreInfo = [
                kCGPDFContextTitle as CFString: metadata.title,
                kCGPDFContextAuthor as CFString: metadata.author,
                kCGPDFContextMediaBox: mediaBoxPerPage
            ] as [CFString : Any]
            context.beginPDFPage(coreInfo as CFDictionary)

            context.setFillColor(CGColor(
                red: 255/255,
                green: 255/255,
                blue: 255/255,
                alpha: 1)
            )
            context.fill(
                CGRect(
                    origin: .zero,
                    size: CGSize(width: width, height: allRowsHeight)
                )
            )

            context.setLineWidth(lineWidth)
#if os(macOS)
            context.setStrokeColor(Color.separatorColor.cgColor)
#elseif os(iOS)
            context.setStrokeColor(Color.separator.cgColor)
#endif
            context.setFillColor(CGColor(
                red: 33/255,
                green: 33/255,
                blue: 33/255,
                alpha: 1
            ))

            setColumnText(
                context: context,
                columns: columns,
                boxWidth: CGFloat(columnWidth),
                boxHeight: CGFloat(rowHeight),
                totalHeight: CGFloat(pageHeight),
                totalWidth: CGFloat(width)
            )
            // `Csv.Row.index` begins with `1`.
            let rows = rows.filter({
                (startRowIndex..<startRowIndex+maxNumberOfRowsInPage)
                    .contains($0.index-1)
            })
            setRowText(
                context: context,
                styles: styles,
                rows: rows,
                from: 0,
                rowCountPerPage: maxNumberOfRowsInPage,
                columnHeight: CGFloat(rowHeight),
                width: CGFloat(columnWidth),
                height: CGFloat(rowHeight),
                totalWidth: CGFloat(width),
                totalHeight: CGFloat(pageHeight)
            )

            context.drawPath(using: .stroke)

            completeFraction += 1
            progress(completeFraction / completeCount)

            currentPageNumber += 1
            startRowIndex += maxNumberOfRowsInPage

            context.endPDFPage()
        }

#if os(iOS)
        UIGraphicsEndPDFContext()
#endif

        context.closePDF()

        let document = PDFDocument(data: data as Data)!
        self.latestOutput = document
        return document
    }

    func setMetadata(_ metadata: PDFMetadata) {
        self.metadata = metadata
    }
}

extension PdfMaker {
    private func setRowText(
        context: CGContext,
        styles: [Csv.Column.Style],
        rows: [Csv.Row],
        from start: Int,
        rowCountPerPage rowCount: Int,
        columnHeight: CGFloat,
        width: CGFloat,
        height: CGFloat,
        totalWidth: CGFloat,
        totalHeight: CGFloat
    ) {
        for i in start..<start+rowCount {
            if rows.count <= i {
                break
            }
            let row = rows[i]
            context.move(
                to: CGPoint(
                    x: 0,
                    y: totalHeight - CGFloat(i + 1) * height - columnHeight
                )
            )
            context.addLine(
                to: CGPoint(
                    x: totalWidth,
                    y: totalHeight - CGFloat(i + 1) * height - columnHeight
                )
            )
            for (j, text) in row.values.enumerated() {
                if text.isEmpty || j >= styles.count {
                    continue
                }
                let style = styles[j]
                let str = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: Font.systemFont(ofSize: fontSize),
                        .foregroundColor: style.displayableColor()
                    ]
                )
                let size = str.string.getSize(fontSize: fontSize)
                let leadingSpaceInBox = (width - size.width) / 2
                let originX = CGFloat(j) * width + leadingSpaceInBox
                let topSpaceInBox = (height - size.height) / 2
                let originY = totalHeight - (CGFloat(i + 1) * height + size.height + topSpaceInBox)
                let framesetter = CTFramesetterCreateWithAttributedString(str)
                context.textMatrix = CGAffineTransform.identity
                let framePath = CGPath(
                    rect: CGRect(
                        origin: CGPoint(x: originX, y: originY),
                        size: size
                    ),
                    transform: nil
                )
                let frameRef = CTFramesetterCreateFrame(
                    framesetter,
                    CFRange(location: 0, length: 0),
                    framePath,
                    nil
                )
                context.saveGState()
                CTFrameDraw(frameRef, context)
                context.restoreGState()
            }
        }
    }

    private func setColumnText(
        context: CGContext,
        columns: [Csv.Column],
        boxWidth width: CGFloat,
        boxHeight height: CGFloat,
        totalHeight: CGFloat,
        totalWidth: CGFloat
    ) {
        context.move(to: CGPoint(x: 0, y: totalHeight - height))
        context.addLine(to: CGPoint(x: totalWidth, y: totalHeight - height))
        for (i, column) in columns.enumerated() {
            let i = CGFloat(i)
            context.move(
                to: CGPoint(
                    x: i * width,
                    y: 0
                )
            )
            context.addLine(
                to: CGPoint(
                    x: i * width,
                    y: totalHeight
                )
            )
            let str = NSAttributedString(
                string: column.name,
                attributes: [
                    .font: Font.systemFont(ofSize: fontSize, weight: .bold),
                    .foregroundColor: column.style.displayableColor()
                ]
            )
            let size = str.string.getSize(fontSize: fontSize)
            let originX = i * width + (width - size.width) / 2
            let originY = totalHeight - (height + size.height) / 2
            let framesetter = CTFramesetterCreateWithAttributedString(str)
            context.saveGState()
            context.textMatrix = CGAffineTransform.identity
            let framePath = CGPath(
                rect: CGRect(
                    origin: CGPoint(x: originX, y: originY),
                    size: size
                ),
                transform: nil
            )
            let frameRef = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: 0, length: 0),
                framePath,
                nil
            )
            CTFrameDraw(frameRef, context)
            context.restoreGState()
        }
    }
}
