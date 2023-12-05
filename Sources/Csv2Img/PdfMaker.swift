import Foundation
import CoreGraphics
import PDFKit

public enum PdfMakingError: Error {
    /// Failed to get/create `CGContext`.
    case noContextAvailabe
    case failedToGeneratePdf
    case failedToSavePdf(
        at : String
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
    private(
        set
    ) var fontSize: Double
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
        return if let size = metadata.size, let orientation = metadata.orientation {
            try make(
                with: size,
                orientation: orientation,
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
        +
        columns
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
        let lineWidth: Double = 1
        
        let width = (
            longestWidth + horizontalSpace
        ) * Double(
            columns.count
        )
        let allRowsHeight = Double(
            rows.count
        ) * (
            longestHeight + verticalSpace
        )
        
        let largestRowsHeight = min(
            maxRowsHeight,
            allRowsHeight
        )
        
        let totalPageNumber = Int(
            allRowsHeight / largestRowsHeight
        )
        
        let totalHeight = allRowsHeight + Double(
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
        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &mediaBox,
            nil
        ) else {
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
            let coreInfo = [
                kCGPDFContextTitle as CFString: metadata.title,
                kCGPDFContextAuthor as CFString: metadata.author,
                kCGPDFContextMediaBox: mediaBoxPerPage
            ] as [CFString : Any]
            context.beginPDFPage(
                coreInfo as CFDictionary
            )
            
            context.setFillColor(
                CGColor(
                    red: 255/255,
                    green: 255/255,
                    blue: 255/255,
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
                    red: 33/255,
                    green: 33/255,
                    blue: 33/255,
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
                (
                    startRowIndex..<startRowIndex+maxNumberOfRowsInPage
                )
                .contains(
                    $0.index-1
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

		let rowHeight = rows[0].values.map { $0.getSize(fontSize: fontSize).height }.max() ?? 0

		let tableSize = CGSize(
			width: pageSize.width * 0.8, height: rowHeight * Double(rows.count + 1)
		)

		let columnWidth = tableSize.width / Double(columns.count)

        let lineWidth: Double = 1

        let totalPageNumber = 1

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
        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &mediaBox,
            nil
        ) else {
            throw PdfMakingError.noContextAvailabe
        }

        let completeCount: Double = Double(
            totalPageNumber
        )
        var completeFraction: Double = 0

        var currentPageNumber: Int = 1
        var startRowIndex: Int = 0
        while currentPageNumber <= totalPageNumber {
            let mediaBoxPerPage = CGRect(
                origin: .zero,
                size: pageSize
            )
            let coreInfo = [
                kCGPDFContextTitle as CFString: metadata.title,
                kCGPDFContextAuthor as CFString: metadata.author,
                kCGPDFContextMediaBox: mediaBoxPerPage
            ] as [CFString : Any]
            context.beginPDFPage(
                coreInfo as CFDictionary
            )

            context.setFillColor(
                CGColor(
                    red: 255/255,
                    green: 255/255,
                    blue: 255/255,
                    alpha: 1
                )
            )
            context.fill(
                CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: pageSize.width,
                        height: pageSize.height
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
                    red: 33/255,
                    green: 33/255,
                    blue: 33/255,
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
				xOffSet: (pageSize.width - tableSize.width) / 2,
				// anchor is bottom-left.
				yOffSet: pageSize.height - tableSize.height - min(24, (pageSize.height - tableSize.height) / 2),
                totalHeight: Double(
					tableSize.height
                ),
                totalWidth: Double(
                    tableSize.width
                )
            )
            setRowText(
                context: context,
                styles: styles,
                rows: rows,
                from: 0,
                rowCountPerPage: rows.count,
                columnHeight: Double(
                    rowHeight
                ),
                width: Double(
                    columnWidth
                ),
                height: Double(
                    rowHeight
                ),
				xOffSet: (pageSize.width - tableSize.width) / 2,
				// anchor is bottom-left.
				yOffSet: pageSize.height - tableSize.height - min(24, (pageSize.height - tableSize.height) / 2),
                totalWidth: Double(
                    tableSize.width
                ),
                totalHeight: Double(
                    tableSize.height
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
            startRowIndex += rows.count

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
        for i in start..<start+rowCount {
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
                        .font: Font.systemFont(
                            ofSize: fontSize
                        ),
                        .foregroundColor: style.displayableColor()
                    ]
                )
                let size = str.string.getSize(
                    fontSize: fontSize
                )
                let leadingSpaceInBox = (
                    width - size.width
                ) / 2
                let originX = xOffSet + Double(
                    j
                ) * width + leadingSpaceInBox
                let topSpaceInBox = (
                    height - size.height
                ) / 2
                let originY = yOffSet + totalHeight - (
                    Double(
                        i + 1
                    ) * height + size.height + topSpaceInBox
                )
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
                    .font: Font.systemFont(
                        ofSize: fontSize,
                        weight: .bold
                    ),
                    .foregroundColor: column.style.displayableColor()
                ]
            )
            let size = str.string.getSize(
                fontSize: fontSize
            )
            let originX = xOffSet + i * width + (
                width - size.width
            ) / 2
            let originY = yOffSet + totalHeight - (
                height + size.height
            ) / 2
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
