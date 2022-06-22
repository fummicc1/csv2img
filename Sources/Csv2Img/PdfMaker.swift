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

        let pageHeight = min(480, height)

        var mediaBoxPerPage = CGRect(
            origin: .zero,
            size: CGSize(
                width: width,
                height: pageHeight
            )
        )
        let coreInfo = [
            kCGPDFContextTitle as CFString: metadata.title,
            kCGPDFContextAuthor as CFString: metadata.author
        ]

        let data = CFDataCreateMutable(nil, 0)!
        let consumer = CGDataConsumer(data: data)!
        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &mediaBoxPerPage,
            nil
        ) else {
            throw PdfMakingError.noContextAvailabe
        }
        context.beginPDFPage(coreInfo as CFDictionary)

        context.setFillColor(CGColor(
            red: 250/255,
            green: 250/255,
            blue: 250/255,
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
            red: 22/255,
            green: 22/255,
            blue: 22/255,
            alpha: 1
        ))

        let columnCount = csv.columnNames.count
        let rowCount = csv.rows.count + 1
        let rowHeight = Int(height) / rowCount
        let columnWidth = Int(width) / columnCount

        var pageNumber: Int = 1
        let numberOfRowsInPage: Int = rowHeight / pageHeight
        var startRowIndex: Int = 0

        while pageNumber * pageHeight <= height {
            setColumnText(
                context: context,
                columns: csv.columnNames,
                boxWidth: columnWidth,
                boxHeight: rowHeight,
                totalHeight: pageHeight
            )
            let rows = csv.rows.filter({
                (startRowIndex..<startRowIndex+numberOfRowsInPage)
                    .contains($0.index)
            })
            setRowText(
                context: context,
                rows: rows,
                from: startRowIndex,
                rowCountPerPage: numberOfRowsInPage,
                width: columnWidth,
                height: rowHeight,
                totalWidth: width
            )
            pageNumber += 1
            startRowIndex += numberOfRowsInPage
        }

        context.drawPath(using: .stroke)
        #if os(iOS)
        UIGraphicsEndPDFContext()
        #endif
        context.endPDFPage()

        context.closePDF()

        return PDFDocument(data: data as Data)!
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
        totalWidth: Int
    ) {
        for i in start..<start+rowCount {
            let row = rows[i]
            context.move(
                to: CGPoint(
                    x: 0,
                    y: i * height
                )
            )
            context.addLine(
                to: CGPoint(
                    x: totalWidth,
                    y: i * height
                )
            )
            for text in row.values {
                let str = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: Font.systemFont(ofSize: fontSize, weight: .bold)
                    ]
                )
                let size = str.string.getSize(fontSize: fontSize)
                let originX = i * width + width / 2 - Int(size.width) / 2
    #if os(macOS)
                let originY = height - Int(size.height) / 2 - height / 2
    #elseif os(iOS)
                let originY = Int(size.height) / 2
                #endif
                context.saveGState()
                str._draw(
                    at: Rect(
                        origin: CGPoint(x: originX, y: originY),
                        size: CGSize(width: width, height: height)
                    )
                )
                context.restoreGState()
            }
        }
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
            let str = NSAttributedString(
                string: column.value,
                attributes: [
                    .font: Font.systemFont(ofSize: fontSize, weight: .bold)
                ]
            )
            let size = str.string.getSize(fontSize: fontSize)
            let originX = i * width + width / 2 - Int(size.width) / 2
            #if os(macOS)
            let originY = height - Int(size.height) / 2 - height / 2
            #elseif os(iOS)
            let originY = Int(size.height) / 2
            #endif
            context.saveGState()
            str._draw(
                at: Rect(
                    origin: CGPoint(x: originX, y: originY),
                    size: CGSize(width: width, height: height)
                )
            )
            context.restoreGState()
        }
    }
}
