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
                widths = proportionallyScale(widths: widths, minWidths: minWidths, targetTotal: available)
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

        let maxCellHeight = values.enumerated().map { (index, value) -> Double in
            guard index < columnWidths.count else { return singleLineHeight() }
            let cellWidth = columnWidths[index] - horizontalPadding * 2
            if cellWidth <= 0 { return singleLineHeight() }

            let singleWidth = Double(value.getSize(fontSize: fontSize).width)
            // Skip CTFramesetter if text fits in single line
            if singleWidth <= cellWidth {
                return singleLineHeight()
            }

            return measureWrappedTextHeight(text: value, constraintWidth: cellWidth)
        }.max() ?? singleLineHeight()

        return maxCellHeight + verticalPadding
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
        let maxHeight = columns.enumerated().map { (index, column) -> Double in
            guard index < columnWidths.count else { return singleLineHeight() }
            let cellWidth = columnWidths[index] - horizontalPadding * 2
            if cellWidth <= 0 { return singleLineHeight() }
            let textWidth = Double(column.name.getSize(fontSize: fontSize).width)
            if textWidth <= cellWidth {
                return singleLineHeight()
            }
            return measureWrappedTextHeight(text: column.name, constraintWidth: cellWidth)
        }.max() ?? singleLineHeight()

        return maxHeight + verticalPadding
    }

    func singleLineHeight() -> Double {
        return Double("Hg".getSize(fontSize: fontSize).height)
    }

    private func measureWrappedTextHeight(text: String, constraintWidth: Double) -> Double {
        let font = text.getFont(ofSize: fontSize)
        let attrString = NSAttributedString(
            string: text,
            attributes: [.font: font]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let constraint = CGSize(width: constraintWidth, height: .greatestFiniteMagnitude)
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter, CFRangeMake(0, 0), nil, constraint, nil
        )
        return Double(suggestedSize.height)
    }

    private func proportionallyScale(widths: [Double], minWidths: [Double], targetTotal: Double) -> [Double] {
        let currentTotal = widths.reduce(0, +)
        guard currentTotal > 0 else { return widths }

        var result = widths.enumerated().map { (i, w) -> Double in
            max(w * targetTotal / currentTotal, minWidths[i])
        }

        // If enforcing minimums pushed total over target, redistribute remaining space
        let minTotal = zip(result, minWidths).reduce(0.0) { acc, pair in
            acc + (pair.0 <= pair.1 ? pair.1 : 0)
        }
        let fixedTotal = result.filter { $0 <= 0 }.count
        if fixedTotal == 0 {
            let scaledTotal = result.reduce(0, +)
            if scaledTotal > targetTotal {
                let excess = scaledTotal - targetTotal
                let shrinkable = result.enumerated().filter { result[$0.offset] > minWidths[$0.offset] }
                let shrinkableTotal = shrinkable.reduce(0.0) { $0 + result[$1.offset] }
                if shrinkableTotal > 0 {
                    for (i, _) in shrinkable {
                        let proportion = result[i] / shrinkableTotal
                        result[i] = max(result[i] - excess * proportion, minWidths[i])
                    }
                }
            }
        }

        return result
    }
}
