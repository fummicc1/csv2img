import CoreGraphics
import CoreText
import Foundation

/// Calculates PDF table layout: column widths, row heights (with text wrapping), and page splitting.
struct PdfLayoutCalculator {

    struct PageLayout {
        let pageSize: CGSize
        let tableOrigin: CGPoint
        let columnWidths: [Double]
        let headerHeight: Double
        let rowHeights: [Double]
        let pages: [PageContent]
    }

    struct PageContent {
        let pageNumber: Int
        let totalPages: Int
        let rowRange: Range<Int>
    }

    let fontSize: Double
    let horizontalPadding: Double
    let verticalPadding: Double
    let pageMargin: Double
    let pageNumberAreaHeight: Double
    private let lineHeight: Double

    init(
        fontSize: Double,
        horizontalPadding: Double = 8,
        verticalPadding: Double = 12,
        pageMargin: Double = 24,
        pageNumberAreaHeight: Double = 20
    ) {
        self.fontSize = fontSize
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.pageMargin = pageMargin
        self.pageNumberAreaHeight = pageNumberAreaHeight
        self.lineHeight = Double("Hg".getSize(fontSize: fontSize).height)
    }

    // MARK: - Public

    func calculateAutoSized(
        columns: [Csv.Column],
        rows: [Csv.Row],
        maxRowsHeight: Double
    ) -> PageLayout {
        let colWidths = calculateColumnWidths(columns: columns, rows: rows, availableWidth: nil)
        let headerHeight = calculateHeaderHeight(columns: columns, columnWidths: colWidths)
        let rowHeights = rows.map { calculateRowHeight(values: $0.values, columnWidths: colWidths) }

        let tableWidth = colWidths.reduce(0, +)
        let totalRowsHeight = rowHeights.reduce(0, +)
        let pageHeight = headerHeight + min(totalRowsHeight, maxRowsHeight) + pageMargin * 2 + pageNumberAreaHeight
        let pageSize = CGSize(width: tableWidth + pageMargin * 2, height: pageHeight)

        let pages = splitIntoPages(
            rowHeights: rowHeights,
            headerHeight: headerHeight,
            availablePageHeight: maxRowsHeight
        )

        return PageLayout(
            pageSize: pageSize,
            tableOrigin: CGPoint(x: pageMargin, y: pageMargin),
            columnWidths: colWidths,
            headerHeight: headerHeight,
            rowHeights: rowHeights,
            pages: pages
        )
    }

    func calculateFixedSize(
        columns: [Csv.Column],
        rows: [Csv.Row],
        pageSize: CGSize
    ) -> PageLayout {
        let availableWidth = pageSize.width - pageMargin * 2
        let colWidths = calculateColumnWidths(columns: columns, rows: rows, availableWidth: availableWidth)
        let headerHeight = calculateHeaderHeight(columns: columns, columnWidths: colWidths)
        let rowHeights = rows.map { calculateRowHeight(values: $0.values, columnWidths: colWidths) }

        let availablePageHeight = pageSize.height - pageMargin * 2 - pageNumberAreaHeight - headerHeight

        let pages = splitIntoPages(
            rowHeights: rowHeights,
            headerHeight: headerHeight,
            availablePageHeight: availablePageHeight
        )

        return PageLayout(
            pageSize: pageSize,
            tableOrigin: CGPoint(x: pageMargin, y: pageMargin),
            columnWidths: colWidths,
            headerHeight: headerHeight,
            rowHeights: rowHeights,
            pages: pages
        )
    }

    // MARK: - Column Widths

    func calculateColumnWidths(
        columns: [Csv.Column],
        rows: [Csv.Row],
        availableWidth: Double?
    ) -> [Double] {
        guard !columns.isEmpty else { return [] }

        var widths = columns.enumerated().map { (index, column) -> Double in
            let headerWidth = Double(column.name.getSize(fontSize: fontSize).width)
            let maxContentWidth = rows.map { row -> Double in
                guard row.values.count > index else { return 0 }
                return Double(row.values[index].getSize(fontSize: fontSize).width)
            }.max() ?? 0
            return max(headerWidth, maxContentWidth) + horizontalPadding * 2
        }

        if let available = availableWidth {
            let totalWidth = widths.reduce(0, +)
            if totalWidth > available {
                let minWidths = columns.map { col -> Double in
                    Double(col.name.getSize(fontSize: fontSize).width) + horizontalPadding * 2
                }
                widths = fit(widths: widths, minWidths: minWidths, targetTotal: available)
            }
        }

        return widths
    }

    // MARK: - Row Heights

    func calculateRowHeight(
        values: [String],
        columnWidths: [Double]
    ) -> Double {
        guard !values.isEmpty else {
            return singleLineHeight() + verticalPadding
        }

        let maxLineCount = values.enumerated().map { (index, value) -> Int in
            guard index < columnWidths.count else { return 1 }
            return wrappedLines(of: value, columnWidth: columnWidths[index]).count
        }.max() ?? 1

        return Double(maxLineCount) * singleLineHeight() + verticalPadding
    }

    // MARK: - Wrapping

    /// Splits a cell text into the lines that fit a column, so that measuring and drawing agree on the result.
    func wrappedLines(of text: String, columnWidth: Double) -> [String] {
        let width = columnWidth - horizontalPadding * 2
        guard width > 0 else { return [text] }
        if !text.contains(where: \.isNewline) {
            return wrappedLines(ofParagraph: text, width: width)
        }
        return text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .flatMap { wrappedLines(ofParagraph: String($0), width: width) }
    }

    private func wrappedLines(ofParagraph text: String, width: Double) -> [String] {
        // Column widths come from this same measurement, so text that fits must not reach the typesetter, which would break it over the fraction of a point lost to rounding.
        if Double(text.getSize(fontSize: fontSize).width) <= width {
            return [text]
        }

        let attributed = NSAttributedString(
            string: text,
            attributes: [.font: text.getFont(ofSize: fontSize)]
        )
        let typesetter = CTTypesetterCreateWithAttributedString(attributed)
        let source = text as NSString
        var lines: [String] = []
        var start = 0
        while start < source.length {
            let suggested = CTTypesetterSuggestLineBreak(typesetter, start, width)
            let length = suggested > 0 ? suggested : source.rangeOfComposedCharacterSequence(at: start).length
            let line = source.substring(with: NSRange(location: start, length: length))
            lines.append(line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression))
            start += length
        }
        return lines.isEmpty ? [text] : lines
    }

    // MARK: - Page Splitting

    func splitIntoPages(
        rowHeights: [Double],
        headerHeight: Double,
        availablePageHeight: Double
    ) -> [PageContent] {
        guard !rowHeights.isEmpty else {
            return [PageContent(pageNumber: 1, totalPages: 1, rowRange: 0..<0)]
        }

        var pages: [Range<Int>] = []
        var currentPageStart = 0
        var remainingHeight = availablePageHeight

        for (index, height) in rowHeights.enumerated() {
            if remainingHeight < height && currentPageStart < index {
                pages.append(currentPageStart..<index)
                currentPageStart = index
                remainingHeight = availablePageHeight
            }
            remainingHeight -= height
        }

        if currentPageStart < rowHeights.count {
            pages.append(currentPageStart..<rowHeights.count)
        }

        let totalPages = pages.count
        return pages.enumerated().map { (i, range) in
            PageContent(pageNumber: i + 1, totalPages: totalPages, rowRange: range)
        }
    }

    // MARK: - Private Helpers

    private func calculateHeaderHeight(columns: [Csv.Column], columnWidths: [Double]) -> Double {
        calculateRowHeight(values: columns.map(\.name), columnWidths: columnWidths)
    }

    func singleLineHeight() -> Double {
        lineHeight
    }

    /// Narrow columns keep their natural width and only the wide ones give up space, so short values are not wrapped because of one long column.
    private func fit(widths: [Double], minWidths: [Double], targetTotal: Double) -> [Double] {
        var result = widths
        var remainingWidth = targetTotal
        var remainingCount = widths.count

        for i in widths.indices.sorted(by: { widths[$0] < widths[$1] }) {
            let share = remainingWidth / Double(remainingCount)
            result[i] = max(min(widths[i], share), minWidths[i])
            remainingWidth -= result[i]
            remainingCount -= 1
        }
        return result
    }
}
