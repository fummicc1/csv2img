import CoreGraphics
import CoreText
import Foundation
import PDFKit

public enum PdfMakingError: Error {
    /// Failed to get/create `CGContext`.
    case noContextAvailabe
    case failedToGeneratePdf
    case failedToSavePdf(
        at: String
    )
    case emptyRows
    case underlying(
        Error
    )
}

/// No overview available
protocol PdfMakerType: Maker {
    var latestOutput: PDFDocument? {
        get
    }
    func set(
        metadata: PDFMetadata
    )
}

/// ``PdfMaker`` generate pdf from ``Csv`` (Work In Progress).
final class PdfMaker: PdfMakerType {

    typealias Exportable = PDFDocument

    init(
        maximumRowCount: Int?,
        fontSize: Double,
        metadata: PDFMetadata
    ) {
        self.maximumRowCount = maximumRowCount
        self.fontSize = fontSize
        self.metadata = metadata
    }

    let maximumRowCount: Int?
    private(set) var fontSize: Double
    var metadata: PDFMetadata

    var latestOutput: PDFDocument?

    func set(
        fontSize size: Double
    ) {
        self.fontSize = size
    }

    /// generate png-image data from ``Csv``.
    func make(
        columns: [Csv.Column],
        rows: [Csv.Row],
        progress: @escaping (
            Double
        ) -> Void
    ) throws -> PDFDocument {
        return if let size = metadata.size {
            try make(
                with: size,
                orientation: metadata.orientation,
                columns: columns,
                rows: rows,
                progress: progress
            )
        } else {
            try make(with: fontSize, columns: columns, rows: rows, progress: progress)
        }
    }

    func make(
        with fontSize: Double,
        columns: [Csv.Column],
        rows: [Csv.Row],
        progress: @escaping (
            Double
        ) -> Void
    ) throws -> PDFDocument {
        // NOTE: Anchor is bottom-left.
        let horizontalSpace: Double = 8
        let verticalSpace: Double = 12
        let maxRowsHeight: Double = 480

        let size = min(
            maximumRowCount ?? rows.count,
            rows.count
        )
        let rows = rows[..<size].map {
            $0
        }

        if rows.isEmpty {
            throw PdfMakingError.emptyRows
        }

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

        let styles: [Csv.Column.Style] = columns.map(
            \.style
        )

        let longestHeight = textSizeList.map({
            $0.height
        }).sorted().reversed()[0]
        let longestWidth = textSizeList.map({
            $0.width
        }).sorted().reversed()[0]

        let rowHeight = longestHeight + verticalSpace
        let columnWidth = longestWidth + horizontalSpace
        let lineWidth: Double = fontSize / 10

        let width =
            (longestWidth + horizontalSpace)
            * Double(
                columns.count
            )
        let allRowsHeight =
            Double(
                rows.count
            ) * (longestHeight + verticalSpace)

        let largestRowsHeight = min(
            maxRowsHeight,
            allRowsHeight
        )

        let totalPageNumber = Int(
            allRowsHeight / largestRowsHeight
        )

        let totalHeight =
            allRowsHeight + Double(
                totalPageNumber
            ) * rowHeight

        let pageHeight = min(
            largestRowsHeight + rowHeight,
            totalHeight
        )

        var mediaBox = CGRect(
            origin: .zero,
            size: CGSize(
                width: width,
                height: pageHeight
            )
        )

        let data = CFDataCreateMutable(
            nil,
            0
        )!
        let consumer = CGDataConsumer(
            data: data
        )!
        let auxInfo = buildMetadataDictionary(mediaBox: mediaBox)
        guard
            let context = CGContext(
                consumer: consumer,
                mediaBox: &mediaBox,
                auxInfo
            )
        else {
            throw PdfMakingError.noContextAvailabe
        }

        // `-1` is due to column space.
        let maxNumberOfRowsInPage: Int = Int(
            ceil(
                pageHeight / rowHeight - 1
            )
        )

        let completeCount: Double = Double(
            totalPageNumber
        )
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
            context.beginPDFPage(
                [kCGPDFContextMediaBox: mediaBoxPerPage] as CFDictionary
            )

            context.setFillColor(
                CGColor(
                    red: 255 / 255,
                    green: 255 / 255,
                    blue: 255 / 255,
                    alpha: 1
                )
            )
            context.fill(
                CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: width,
                        height: allRowsHeight
                    )
                )
            )

            context.setLineWidth(
                lineWidth
            )
            #if os(macOS)
                context.setStrokeColor(
                    Color.separatorColor.cgColor
                )
            #elseif os(iOS)
                context.setStrokeColor(
                    Color.separator.cgColor
                )
            #endif
            context.setFillColor(
                CGColor(
                    red: 33 / 255,
                    green: 33 / 255,
                    blue: 33 / 255,
                    alpha: 1
                )
            )

            setColumnText(
                context: context,
                columns: columns,
                boxWidth: Double(
                    columnWidth
                ),
                boxHeight: Double(
                    rowHeight
                ),
                totalHeight: Double(
                    pageHeight
                ),
                totalWidth: Double(
                    width
                )
            )
            // `Csv.Row.index` begins with `1`.
            let rows = rows.filter({
                (startRowIndex..<startRowIndex + maxNumberOfRowsInPage)
                    .contains(
                        $0.index - 1
                    )
            })
            setRowText(
                context: context,
                styles: styles,
                rows: rows,
                from: 0,
                rowCountPerPage: maxNumberOfRowsInPage,
                columnHeight: Double(
                    rowHeight
                ),
                width: Double(
                    columnWidth
                ),
                height: Double(
                    rowHeight
                ),
                totalWidth: Double(
                    width
                ),
                totalHeight: Double(
                    pageHeight
                )
            )

            context.drawPath(
                using: .stroke
            )

            completeFraction += 1
            progress(
                completeFraction / completeCount
            )

            currentPageNumber += 1
            startRowIndex += maxNumberOfRowsInPage

            context.endPDFPage()
        }

        #if os(iOS)
            UIGraphicsEndPDFContext()
        #endif

        context.closePDF()

        let document = PDFDocument(
            data: data as Data
        )!
        self.latestOutput = document
        return document
    }

    func make(
        with pdfSize: PdfSize,
        orientation: PdfSize.Orientation,
        columns: [Csv.Column],
        rows: [Csv.Row],
        progress: @escaping (
            Double
        ) -> Void
    ) throws -> PDFDocument {
        let pageSize = pdfSize.size(
            orientation: orientation
        )

        let totalRowCount = min(
            maximumRowCount ?? rows.count,
            rows.count
        )
        let rows = rows[..<totalRowCount].map {
            $0
        }

        if rows.isEmpty {
            throw PdfMakingError.emptyRows
        }

        let styles: [Csv.Column.Style] = columns.map(
            \.style
        )

        let calculator = PdfLayoutCalculator(fontSize: fontSize)
        let layout = calculator.calculateFixedSize(
            columns: columns,
            rows: rows,
            pageSize: pageSize
        )

        let lineWidth: Double = fontSize / 10

        var mediaBox = CGRect(
            origin: .zero,
            size: pageSize
        )

        let data = CFDataCreateMutable(
            nil,
            0
        )!
        let consumer = CGDataConsumer(
            data: data
        )!
        let auxInfo = buildMetadataDictionary(mediaBox: mediaBox)
        guard
            let context = CGContext(
                consumer: consumer,
                mediaBox: &mediaBox,
                auxInfo
            )
        else {
            throw PdfMakingError.noContextAvailabe
        }

        let completeCount = Double(layout.pages.count)
        var completeFraction: Double = 0

        for page in layout.pages {
            let mediaBoxPerPage = CGRect(
                origin: .zero,
                size: pageSize
            )
            context.beginPDFPage(
                [kCGPDFContextMediaBox: mediaBoxPerPage] as CFDictionary
            )

            // Fill white background
            context.setFillColor(
                CGColor(
                    red: 255 / 255,
                    green: 255 / 255,
                    blue: 255 / 255,
                    alpha: 1
                )
            )
            context.fill(
                CGRect(
                    origin: .zero,
                    size: pageSize
                )
            )

            context.setLineWidth(lineWidth)
            #if os(macOS)
                context.setStrokeColor(
                    Color.separatorColor.cgColor
                )
            #elseif os(iOS)
                context.setStrokeColor(
                    Color.separator.cgColor
                )
            #endif
            context.setFillColor(
                CGColor(
                    red: 33 / 255,
                    green: 33 / 255,
                    blue: 33 / 255,
                    alpha: 1
                )
            )

            // Calculate the table height for this page (header + rows on this page)
            let pageRowHeights = layout.rowHeights[page.rowRange]
            let pageTableHeight = layout.headerHeight + pageRowHeights.reduce(0, +)

            // Center the table horizontally; place from the top with margin
            let xOffset = layout.tableOrigin.x
            let yBase = pageSize.height - calculator.pageMargin - pageTableHeight

            drawHeaderRow(
                context: context,
                columns: columns,
                columnWidths: layout.columnWidths,
                headerHeight: layout.headerHeight,
                xOffset: xOffset,
                yBase: yBase,
                pageTableHeight: pageTableHeight
            )

            drawDataRows(
                context: context,
                styles: styles,
                rows: rows,
                columnWidths: layout.columnWidths,
                rowHeights: layout.rowHeights,
                headerHeight: layout.headerHeight,
                page: page,
                xOffset: xOffset,
                yBase: yBase
            )

            context.drawPath(using: .stroke)

            drawPageNumber(
                context: context,
                pageNumber: page.pageNumber,
                totalPages: page.totalPages,
                pageSize: pageSize,
                bottomMargin: calculator.pageMargin
            )

            completeFraction += 1
            progress(completeFraction / completeCount)

            context.endPDFPage()
        }

        #if os(iOS)
            UIGraphicsEndPDFContext()
        #endif

        context.closePDF()

        let document = PDFDocument(
            data: data as Data
        )!
        self.latestOutput = document
        return document
    }

    func set(
        metadata: PDFMetadata
    ) {
        self.metadata = metadata
    }
}

extension PdfMaker {

    // MARK: - Metadata

    private func buildMetadataDictionary(mediaBox: CGRect) -> CFDictionary {
        var dict: [CFString: Any] = [
            kCGPDFContextMediaBox: mediaBox
        ]
        if let title = metadata.title {
            dict[kCGPDFContextTitle] = title
        }
        if let author = metadata.author {
            dict[kCGPDFContextAuthor] = author
        }
        if let subject = metadata.subject {
            dict[kCGPDFContextSubject] = subject
        }
        if let keywords = metadata.keywords, !keywords.isEmpty {
            dict[kCGPDFContextKeywords] = keywords as CFArray
        }
        if let creator = metadata.creator {
            dict[kCGPDFContextCreator] = creator
        }
        return dict as CFDictionary
    }

    // MARK: - Variable-width drawing helpers

    /// Draws the header row with variable column widths and grid lines for the full table.
    private func drawHeaderRow(
        context: CGContext,
        columns: [Csv.Column],
        columnWidths: [Double],
        headerHeight: Double,
        xOffset: Double,
        yBase: Double,
        pageTableHeight: Double
    ) {
        let tableWidth = columnWidths.reduce(0, +)
        let tableTop = yBase + pageTableHeight
        let headerBottom = tableTop - headerHeight

        // Top border line
        context.move(to: CGPoint(x: xOffset, y: tableTop))
        context.addLine(to: CGPoint(x: xOffset + tableWidth, y: tableTop))

        // Header-data separator line
        context.move(to: CGPoint(x: xOffset, y: headerBottom))
        context.addLine(to: CGPoint(x: xOffset + tableWidth, y: headerBottom))

        // Bottom border line
        context.move(to: CGPoint(x: xOffset, y: yBase))
        context.addLine(to: CGPoint(x: xOffset + tableWidth, y: yBase))

        // Vertical column separators (full height)
        var colX = xOffset
        for (i, colWidth) in columnWidths.enumerated() {
            // Left edge of each column
            context.move(to: CGPoint(x: colX, y: yBase))
            context.addLine(to: CGPoint(x: colX, y: tableTop))

            // Draw header text centered in cell
            let column = columns[i]
            let str = NSAttributedString(
                string: column.name,
                attributes: [
                    .font: column.name.getFont(ofSize: fontSize),
                    .foregroundColor: column.style.displayableColor(),
                ]
            )
            let textSize = str.string.getSize(fontSize: fontSize)
            let cellCenterX = colX + (colWidth - textSize.width) / 2
            let cellCenterY = headerBottom + (headerHeight - textSize.height) / 2

            drawText(str, at: CGPoint(x: cellCenterX, y: cellCenterY), in: context)

            colX += colWidth
        }

        // Right border line
        context.move(to: CGPoint(x: xOffset + tableWidth, y: yBase))
        context.addLine(to: CGPoint(x: xOffset + tableWidth, y: tableTop))
    }

    /// Draws data rows for a specific page with variable column widths and row heights.
    /// - `yBase`: bottom Y coordinate of the entire table on this page.
    private func drawDataRows(
        context: CGContext,
        styles: [Csv.Column.Style],
        rows: [Csv.Row],
        columnWidths: [Double],
        rowHeights: [Double],
        headerHeight: Double,
        page: PdfLayoutCalculator.PageContent,
        xOffset: Double,
        yBase: Double
    ) {
        let pageRowHeights = Array(rowHeights[page.rowRange])
        let dataAreaHeight = pageRowHeights.reduce(0, +)
        // Data area top sits just below the header
        let dataAreaTop = yBase + dataAreaHeight

        // Draw each row from top to bottom (highest Y to lowest Y)
        var currentY = dataAreaTop
        for (localIndex, globalIndex) in page.rowRange.enumerated() {
            let rowH = pageRowHeights[localIndex]
            let rowBottom = currentY - rowH

            // Horizontal separator at row bottom
            context.move(to: CGPoint(x: xOffset, y: rowBottom))
            context.addLine(
                to: CGPoint(x: xOffset + columnWidths.reduce(0, +), y: rowBottom)
            )

            let row = rows[globalIndex]
            var colX = xOffset
            for (colIndex, text) in row.values.enumerated() {
                guard colIndex < columnWidths.count, colIndex < styles.count else { continue }
                if text.isEmpty {
                    colX += columnWidths[colIndex]
                    continue
                }

                let style = styles[colIndex]
                let colWidth = columnWidths[colIndex]
                let str = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: text.getFont(ofSize: fontSize),
                        .foregroundColor: style.displayableColor(),
                    ]
                )
                let textSize = str.string.getSize(fontSize: fontSize)

                // Center text horizontally, vertically within the cell
                let cellCenterX = colX + (colWidth - textSize.width) / 2
                let cellCenterY = rowBottom + (rowH - textSize.height) / 2

                drawText(str, at: CGPoint(x: cellCenterX, y: cellCenterY), in: context)

                colX += colWidth
            }

            currentY = rowBottom
        }
    }

    /// Draws page number text ("N / M") centered at the bottom of the page.
    private func drawPageNumber(
        context: CGContext,
        pageNumber: Int,
        totalPages: Int,
        pageSize: CGSize,
        bottomMargin: Double
    ) {
        let text = "\(pageNumber) / \(totalPages)"
        let str = NSAttributedString(
            string: text,
            attributes: [
                .font: text.getFont(ofSize: fontSize)
            ]
        )
        let textSize = text.getSize(fontSize: fontSize)
        let originX = (pageSize.width - textSize.width) / 2
        let originY = bottomMargin / 2 - textSize.height / 2

        drawText(str, at: CGPoint(x: originX, y: max(originY, 4)), in: context)
    }

    /// Draws an attributed string at the given position using CTLine (more reliable than CTFrame in PDF contexts).
    private func drawText(
        _ attributedString: NSAttributedString,
        at point: CGPoint,
        in context: CGContext
    ) {
        let line = CTLineCreateWithAttributedString(attributedString)
        context.saveGState()
        context.textMatrix = CGAffineTransform.identity
        context.textPosition = point
        CTLineDraw(line, context)
        context.restoreGState()
    }

    // MARK: - Legacy uniform-width drawing helpers

    private func setRowText(
        context: CGContext,
        styles: [Csv.Column.Style],
        rows: [Csv.Row],
        from start: Int,
        rowCountPerPage rowCount: Int,
        columnHeight: Double,
        width: Double,
        height: Double,
        xOffSet: Double = 0,
        yOffSet: Double = 0,
        totalWidth: Double,
        totalHeight: Double
    ) {
        for i in start..<start + rowCount {
            if rows.count <= i {
                break
            }
            let row = rows[i]
            context.move(
                to: CGPoint(
                    x: xOffSet,
                    y: yOffSet + totalHeight - Double(
                        i + 1
                    ) * height - columnHeight
                )
            )
            context.addLine(
                to: CGPoint(
                    x: xOffSet + totalWidth,
                    y: yOffSet + totalHeight - Double(
                        i + 1
                    ) * height - columnHeight
                )
            )
            for (
                j,
                text
            ) in row.values.enumerated() {
                if text.isEmpty || j >= styles.count {
                    continue
                }
                let style = styles[j]
                let str = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: text.getFont(ofSize: fontSize),
                        .foregroundColor: style.displayableColor(),
                    ]
                )
                let size = str.string.getSize(
                    fontSize: fontSize
                )
                let leadingSpaceInBox = (width - size.width) / 2
                let originX =
                    xOffSet + Double(
                        j
                    ) * width + leadingSpaceInBox
                let topSpaceInBox = (height - size.height) / 2
                let originY =
                    yOffSet + totalHeight
                    - (Double(
                        i + 1
                    ) * height + size.height + topSpaceInBox)
                let framesetter = CTFramesetterCreateWithAttributedString(
                    str
                )
                context.textMatrix = CGAffineTransform.identity
                let framePath = CGPath(
                    rect: CGRect(
                        origin: CGPoint(
                            x: originX,
                            y: originY
                        ),
                        size: size
                    ),
                    transform: nil
                )
                let frameRef = CTFramesetterCreateFrame(
                    framesetter,
                    CFRange(
                        location: 0,
                        length: 0
                    ),
                    framePath,
                    nil
                )
                context.saveGState()
                CTFrameDraw(
                    frameRef,
                    context
                )
                context.restoreGState()
            }
        }
    }

    private func setColumnText(
        context: CGContext,
        columns: [Csv.Column],
        boxWidth width: Double,
        boxHeight height: Double,
        xOffSet: Double = 0,
        yOffSet: Double = 0,
        totalHeight: Double,
        totalWidth: Double
    ) {
        // Draw top `-`.
        context.move(
            to: CGPoint(
                x: xOffSet,
                y: yOffSet + totalHeight
            )
        )
        context.addLine(
            to: CGPoint(
                x: totalWidth + xOffSet,
                y: yOffSet + totalHeight
            )
        )

        // Draw top-column `-`.
        context.move(
            to: CGPoint(
                x: xOffSet,
                y: yOffSet + totalHeight - height
            )
        )
        context.addLine(
            to: CGPoint(
                x: totalWidth + xOffSet,
                y: yOffSet + totalHeight - height
            )
        )

        // Draw right `|`.
        context.move(
            to: CGPoint(
                x: xOffSet + totalWidth,
                y: yOffSet
            )
        )
        context.addLine(
            to: CGPoint(
                x: xOffSet + totalWidth,
                y: yOffSet + totalHeight
            )
        )
        for (
            i,
            column
        ) in columns.enumerated() {
            let i = Double(
                i
            )
            context.move(
                to: CGPoint(
                    x: xOffSet + i * width,
                    y: yOffSet
                )
            )
            context.addLine(
                to: CGPoint(
                    x: xOffSet + i * width,
                    y: yOffSet + totalHeight
                )
            )
            let str = NSAttributedString(
                string: column.name,
                attributes: [
                    .font: column.name.getFont(ofSize: fontSize),
                    .foregroundColor: column.style.displayableColor(),
                ]
            )
            let size = str.string.getSize(
                fontSize: fontSize
            )
            let originX = xOffSet + i * width + (width - size.width) / 2
            let originY = yOffSet + totalHeight - (height + size.height) / 2
            let framesetter = CTFramesetterCreateWithAttributedString(
                str
            )
            context.saveGState()
            context.textMatrix = CGAffineTransform.identity
            let framePath = CGPath(
                rect: CGRect(
                    origin: CGPoint(
                        x: originX,
                        y: originY
                    ),
                    size: size
                ),
                transform: nil
            )
            let frameRef = CTFramesetterCreateFrame(
                framesetter,
                CFRange(
                    location: 0,
                    length: 0
                ),
                framePath,
                nil
            )
            CTFrameDraw(
                frameRef,
                context
            )
            context.restoreGState()
        }
    }
}
