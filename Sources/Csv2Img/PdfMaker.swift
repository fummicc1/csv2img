import Foundation
import CoreGraphics
import PDFKit

public enum PdfMakingError: Error {
    /// Failed to get/create `CGContext`.
    case noContextAvailabe
    case failedToGeneratePdf
}

/// No overview available
protocol PdfMakerType: Maker {
    var latestOutput: PDFDocument? { get }
    func make(csv: Csv) throws -> PDFDocument
    func setMetadata(_ metadata: PDFMetadata)
    func setFontSize(_ size: CGFloat)
}

/// ``PdfMaker`` generate pdf from ``Csv`` (Work In Progress).
class PdfMaker: PdfMakerType {

    typealias Exportable = PDFDocument

    init(
        fontSize: CGFloat,
        metadata: PDFMetadata
    ) {
        self.fontSize = fontSize
        self.metadata = metadata
    }

    var fontSize: CGFloat
    var metadata: PDFMetadata

    var latestOutput: PDFDocument?

    func setFontSize(_ size: CGFloat) {
        self.fontSize = size
    }


    /// generate png-image data from ``Csv``.
    func make(
        csv: Csv
    ) throws -> PDFDocument {
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

        let maxPageHeight = min(480, height)

        var mediaBox = CGRect(
            origin: .zero,
            size: CGSize(
                width: width,
                height: maxPageHeight
            )
        )

        let coreInfo = [
            kCGPDFContextTitle as CFString: metadata.title,
            kCGPDFContextAuthor as CFString: metadata.author
        ]

        let data = CFDataCreateMutable(nil, 32 * Int(1 << 40))!
        let consumer = CGDataConsumer(data: data)!
        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &mediaBox,
            nil
        ) else {
            throw PdfMakingError.noContextAvailabe
        }
        // Maybe also create first page.
        context.beginPDFPage(coreInfo as CFDictionary)

        let rowHeight: Int = Int(longestHeight) + verticalSpace
        let columnWidth: Int = Int(longestWidth) + horizontalSpace

        var pageNumber: Int = 0
        // `-1` is due to column space.
        let maxNumberOfRowsInPage: Int = maxPageHeight / rowHeight - 1
        var startRowIndex: Int = 0

        while pageNumber * maxPageHeight < height {
            let pageHeight = min(
                maxPageHeight,
                height - pageNumber * maxPageHeight
            )
            if pageNumber > 0 {
                context.endPage()
                var mediaBoxPerPage = CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: width,
                        height: pageHeight
                    )
                )
                context.beginPage(mediaBox: &mediaBoxPerPage)
            }

            context.setFillColor(CGColor(
                red: 255/255,
                green: 255/255,
                blue: 255/255,
                alpha: 1)
            )
            context.fill(
                CGRect(
                    origin: .zero,
                    size: CGSize(width: width, height: height)
                )
            )

            context.setLineWidth(1)
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
                columns: csv.columnNames,
                boxWidth: columnWidth,
                boxHeight: rowHeight,
                totalHeight: maxPageHeight
            )
            // `Csv.Row.index` begins with `1`.
            let rows = csv.rows.filter({
                (startRowIndex..<startRowIndex+maxNumberOfRowsInPage)
                    .contains($0.index-1)
            })
            setRowText(
                context: context,
                rows: rows,
                from: 0,
                rowCountPerPage: maxNumberOfRowsInPage,
                width: columnWidth,
                height: rowHeight,
                totalWidth: width,
                totalHeight: pageHeight
            )

            context.drawPath(using: .stroke)

            pageNumber += 1
            startRowIndex += maxNumberOfRowsInPage
        }
        context.endPage()
        #if os(iOS)
        UIGraphicsEndPDFContext()
        #endif
        context.endPDFPage()

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
        rows: [Csv.Row],
        from start: Int,
        rowCountPerPage rowCount: Int,
        width: Int,
        height: Int,
        totalWidth: Int,
        totalHeight: Int
    ) {
        for i in start..<start+rowCount {
            if rows.count <= i {
                break
            }
            let row = rows[i]
            context.move(
                to: CGPoint(
                    x: 0,
                    y: (rowCount - i) * height
                )
            )
            context.addLine(
                to: CGPoint(
                    x: totalWidth,
                    y: (rowCount - i) * height
                )
            )

#if os(macOS)
            let color = NSColor.labelColor.cgColor
#elseif os(iOS)
            let color = UIColor.label.cgColor
#endif
            for (j, text) in row.values.enumerated() {
                if text.isEmpty {
                    continue
                }
                let str = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: Font.systemFont(ofSize: fontSize, weight: .bold),
                        .foregroundColor: color
                    ]
                )
                let size = str.string.getSize(fontSize: fontSize)
                let leadingSpaceInBox = (width - Int(size.width)) / 2
                let originX = j * width + leadingSpaceInBox
                let topSpaceInBox = (height - Int(size.height)) / 2
    #if os(macOS)
                let originY = (rows.count - (i + 1)) * height + topSpaceInBox
    #elseif os(iOS)
                let originY = totalHeight - i * height + topSpaceInBox
                #endif
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
        // the bottoming line.
        context.move(
            to: CGPoint(
                x: 0,
                y: totalHeight - rows.count * height
            )
        )
    }

    private func setColumnText(
        context: CGContext,
        columns: [Csv.ColumnName],
        boxWidth width: Int,
        boxHeight height: Int,
        totalHeight: Int
    ) {
        for (i, column) in columns.enumerated() {
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
#if os(macOS)
            let color = NSColor.labelColor.cgColor
#elseif os(iOS)
            let color = UIColor.label.cgColor
#endif
            let str = NSAttributedString(
                string: column.value,
                attributes: [
                    .font: Font.systemFont(ofSize: fontSize, weight: .bold),
                    .foregroundColor: color
                ]
            )
            let size = str.string.getSize(fontSize: fontSize)
            let originX = i * width + (width - Int(size.width)) / 2
            #if os(macOS)
            let originY = totalHeight - (height + Int(size.height)) / 2
            #elseif os(iOS)
            let originY = Int(size.height) / 2
            #endif
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
