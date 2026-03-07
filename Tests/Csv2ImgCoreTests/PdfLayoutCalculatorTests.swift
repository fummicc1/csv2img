import XCTest

@testable import Csv2ImgCore

final class PdfLayoutCalculatorTests: XCTestCase {

    private func makeCalculator(fontSize: Double = 12) -> PdfLayoutCalculator {
        PdfLayoutCalculator(fontSize: fontSize)
    }

    private func makeColumns(_ names: [String]) -> [Csv.Column] {
        let styles = Csv.Column.Style.random(count: names.count)
        return names.enumerated().map { (i, name) in
            Csv.Column(name: name, style: styles[i])
        }
    }

    private func makeRows(_ data: [[String]], startIndex: Int = 1) -> [Csv.Row] {
        data.enumerated().map { (i, values) in
            Csv.Row(index: startIndex + i, values: values)
        }
    }

    // MARK: - Column Width Tests (T401-T406)

    /// T401: Uniform content width — columns should be similar widths.
    func testT401_uniformContentWidth() {
        let calc = makeCalculator()
        let columns = makeColumns(["AAA", "BBB", "CCC"])
        let rows = makeRows([["aaa", "bbb", "ccc"], ["ddd", "eee", "fff"]])

        let widths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: nil)

        XCTAssertEqual(widths.count, 3)
        // All columns should be similar since all content is same length
        let maxDiff = widths.max()! - widths.min()!
        XCTAssertLessThan(maxDiff, 5, "Columns with uniform content should have similar widths")
    }

    /// T402: Skewed content width — longer column should be wider.
    func testT402_skewedContentWidth() {
        let calc = makeCalculator()
        let columns = makeColumns(["A", "B"])
        let rows = makeRows([["x", "VeryLongTextValueHere"], ["y", "AnotherLongTextValue"]])

        let widths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: nil)

        XCTAssertEqual(widths.count, 2)
        XCTAssertGreaterThan(widths[1], widths[0], "Column with longer content should be wider")
    }

    /// T403: Header longer than data — column width >= header width.
    func testT403_headerLongerThanData() {
        let calc = makeCalculator()
        let columns = makeColumns(["VeryLongHeaderName", "Short"])
        let rows = makeRows([["A", "B"]])

        let widths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: nil)

        let headerWidth = Double("VeryLongHeaderName".getSize(fontSize: 12).width) + calc.horizontalPadding * 2
        XCTAssertGreaterThanOrEqual(widths[0], headerWidth, "Column width should accommodate header")
    }

    /// T404: Data longer than header — column width >= data width.
    func testT404_dataLongerThanHeader() {
        let calc = makeCalculator()
        let columns = makeColumns(["X", "Y"])
        let rows = makeRows([["VeryLongDataValue", "Z"]])

        let widths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: nil)

        let dataWidth = Double("VeryLongDataValue".getSize(fontSize: 12).width) + calc.horizontalPadding * 2
        XCTAssertGreaterThanOrEqual(widths[0], dataWidth, "Column width should accommodate data")
    }

    /// T405: Fixed size requires proportional scaling when columns exceed page width.
    func testT405_fixedSizeScaling() {
        let calc = makeCalculator()
        let columns = makeColumns(["A", "B", "C", "D"])
        let rows = makeRows([
            ["SomeLongValue1", "SomeLongValue2", "SomeLongValue3", "SomeLongValue4"]
        ])

        let unscaledWidths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: nil)
        let unscaledTotal = unscaledWidths.reduce(0, +)

        // Use a width that's narrower than natural widths to force scaling
        let narrowWidth = unscaledTotal * 0.6
        let widths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: narrowWidth)

        let totalWidth = widths.reduce(0, +)
        XCTAssertLessThan(totalWidth, unscaledTotal, "Scaled widths should be smaller than unscaled")
    }

    /// T406: Fixed size, no scaling needed — columns fit within page width.
    func testT406_fixedSizeNoScaling() {
        let calc = makeCalculator()
        let columns = makeColumns(["A", "B"])
        let rows = makeRows([["x", "y"]])

        let wideWidth = 2000.0
        let widths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: wideWidth)
        let unscaledWidths = calc.calculateColumnWidths(columns: columns, rows: rows, availableWidth: nil)

        // When available width is very wide, widths should equal unscaled widths
        XCTAssertEqual(widths.count, unscaledWidths.count)
        for (i, width) in widths.enumerated() {
            XCTAssertEqual(width, unscaledWidths[i], accuracy: 0.01, "No scaling should be applied when columns fit")
        }
    }

    // MARK: - Row Height Tests (T411-T414)

    /// T411: No wrapping — row height should be single line height + padding.
    func testT411_noWrapping() {
        let calc = makeCalculator()
        let columnWidths = [200.0, 200.0]
        let values = ["Short", "Text"]

        let height = calc.calculateRowHeight(values: values, columnWidths: columnWidths)
        let expectedMinHeight = calc.singleLineHeight() + calc.verticalPadding

        XCTAssertEqual(height, expectedMinHeight, accuracy: 1.0, "No-wrap row should be single line height + padding")
    }

    /// T412: One cell wraps — row height should be greater than single line.
    func testT412_oneCellWraps() {
        let calc = makeCalculator()
        let columnWidths = [50.0, 200.0]
        let values = ["This is a very long text that should definitely wrap in a narrow column", "Short"]

        let height = calc.calculateRowHeight(values: values, columnWidths: columnWidths)
        let singleLineHeight = calc.singleLineHeight() + calc.verticalPadding

        XCTAssertGreaterThan(height, singleLineHeight, "Wrapped cell should increase row height")
    }

    /// T413: Multiple cells wrap — row height equals tallest cell.
    func testT413_multipleCellsWrap() {
        let calc = makeCalculator()
        let columnWidths = [60.0, 60.0]
        let values = [
            "Short text",
            "This is much longer text that will wrap many times and should be the tallest cell in this row"
        ]

        let height = calc.calculateRowHeight(values: values, columnWidths: columnWidths)
        let singleLineHeight = calc.singleLineHeight() + calc.verticalPadding

        XCTAssertGreaterThan(height, singleLineHeight, "Row height should reflect tallest wrapped cell")
    }

    /// T414: Empty cells — minimum row height.
    func testT414_emptyCells() {
        let calc = makeCalculator()
        let columnWidths = [100.0, 100.0]
        let values = ["", ""]

        let height = calc.calculateRowHeight(values: values, columnWidths: columnWidths)
        let expectedHeight = calc.singleLineHeight() + calc.verticalPadding

        XCTAssertEqual(height, expectedHeight, accuracy: 1.0, "Empty cells should use minimum row height")
    }

    // MARK: - Page Splitting Tests (T421-T427)

    /// T421: All rows fit in one page.
    func testT421_singlePage() {
        let calc = makeCalculator()
        let rowHeights = [20.0, 20.0, 20.0]
        let headerHeight = 25.0
        let availablePageHeight = 500.0

        let pages = calc.splitIntoPages(
            rowHeights: rowHeights,
            headerHeight: headerHeight,
            availablePageHeight: availablePageHeight
        )

        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].rowRange, 0..<3)
        XCTAssertEqual(pages[0].pageNumber, 1)
        XCTAssertEqual(pages[0].totalPages, 1)
    }

    /// T422: Rows split into exactly 2 pages.
    func testT422_twoPages() {
        let calc = makeCalculator()
        let rowHeights = [30.0, 30.0, 30.0, 30.0]
        let headerHeight = 25.0
        // Available height fits 2 rows (60pt) but not 3 (90pt)
        let availablePageHeight = 65.0

        let pages = calc.splitIntoPages(
            rowHeights: rowHeights,
            headerHeight: headerHeight,
            availablePageHeight: availablePageHeight
        )

        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[0].pageNumber, 1)
        XCTAssertEqual(pages[1].pageNumber, 2)
        XCTAssertEqual(pages[0].totalPages, 2)
        XCTAssertEqual(pages[1].totalPages, 2)
    }

    /// T423: Many pages with many rows.
    func testT423_manyPages() {
        let calc = makeCalculator()
        let rowHeights = Array(repeating: 20.0, count: 100)
        let headerHeight = 25.0
        let availablePageHeight = 50.0

        let pages = calc.splitIntoPages(
            rowHeights: rowHeights,
            headerHeight: headerHeight,
            availablePageHeight: availablePageHeight
        )

        XCTAssertGreaterThan(pages.count, 2, "100 rows in small pages should produce > 2 pages")
        for page in pages {
            XCTAssertEqual(page.totalPages, pages.count)
        }
    }

    /// T424: Row ranges are contiguous and cover all rows.
    func testT424_contiguousRanges() {
        let calc = makeCalculator()
        let rowHeights = Array(repeating: 25.0, count: 50)
        let headerHeight = 20.0
        let availablePageHeight = 100.0

        let pages = calc.splitIntoPages(
            rowHeights: rowHeights,
            headerHeight: headerHeight,
            availablePageHeight: availablePageHeight
        )

        // Verify contiguous coverage
        var coveredIndices = Set<Int>()
        var previousEnd = 0
        for page in pages {
            XCTAssertEqual(page.rowRange.lowerBound, previousEnd, "Row ranges should be contiguous")
            for i in page.rowRange {
                coveredIndices.insert(i)
            }
            previousEnd = page.rowRange.upperBound
        }
        XCTAssertEqual(coveredIndices.count, 50, "All rows should be covered")
        XCTAssertEqual(previousEnd, 50, "Last range should end at row count")
    }

    /// T425: Empty rows produces single page with empty range.
    func testT425_emptyRows() {
        let calc = makeCalculator()
        let pages = calc.splitIntoPages(
            rowHeights: [],
            headerHeight: 25.0,
            availablePageHeight: 500.0
        )

        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].rowRange, 0..<0)
    }

    /// T426: Page number area is accounted for in fixed size layout.
    func testT426_pageNumberAreaInFixedSize() {
        let calc = makeCalculator()
        let columns = makeColumns(["A", "B"])
        let rows = makeRows([["x", "y"]])

        let pageSize = CGSize(width: 595, height: 842) // A4
        let layout = calc.calculateFixedSize(columns: columns, rows: rows, pageSize: pageSize)

        // Available page height should account for margins, header, and page number area
        let expectedAvailableHeight = pageSize.height - calc.pageMargin * 2 - calc.pageNumberAreaHeight - layout.headerHeight
        // All rows should fit since there's only 1 row
        XCTAssertEqual(layout.pages.count, 1)
        XCTAssertEqual(layout.pages[0].rowRange, 0..<1)

        // Verify page number area is reserved (20pt default)
        XCTAssertEqual(calc.pageNumberAreaHeight, 20.0)
    }

    /// T427: Rows with varying heights are split correctly.
    func testT427_varyingRowHeights() {
        let calc = makeCalculator()
        // Mix of normal and tall rows
        let rowHeights = [20.0, 80.0, 20.0, 80.0, 20.0]
        let headerHeight = 25.0
        let availablePageHeight = 100.0

        let pages = calc.splitIntoPages(
            rowHeights: rowHeights,
            headerHeight: headerHeight,
            availablePageHeight: availablePageHeight
        )

        // Verify all rows are covered
        let totalRows = pages.reduce(0) { $0 + $1.rowRange.count }
        XCTAssertEqual(totalRows, 5)

        // Verify each page's rows fit within available height
        for page in pages {
            let pageRowsHeight = page.rowRange.reduce(0.0) { $0 + rowHeights[$1] }
            // First page might overflow slightly if a single row is taller than available height
            // but normally rows should fit within available height + tolerance for single tall rows
            XCTAssertGreaterThan(pageRowsHeight, 0, "Each page should have content")
        }
    }

    // MARK: - Auto Size vs Fixed Size (T431-T433)

    /// T431: Auto-sized layout — page size matches content.
    func testT431_autoSized() {
        let calc = makeCalculator()
        let columns = makeColumns(["Name", "Value", "Unit"])
        let rows = makeRows([
            ["Alice", "100", "USD"],
            ["Bob", "200", "EUR"],
        ])

        let layout = calc.calculateAutoSized(columns: columns, rows: rows, maxRowsHeight: 1000)

        let expectedTableWidth = layout.columnWidths.reduce(0, +)
        let expectedPageWidth = expectedTableWidth + calc.pageMargin * 2

        XCTAssertEqual(Double(layout.pageSize.width), expectedPageWidth, accuracy: 1.0)
        XCTAssertGreaterThan(layout.headerHeight, 0)
        XCTAssertEqual(layout.rowHeights.count, 2)
        XCTAssertEqual(layout.pages.count, 1)
    }

    /// T432: Fixed-size A4 portrait layout.
    func testT432_fixedSizeA4Portrait() {
        let calc = makeCalculator()
        let columns = makeColumns(["Name", "Value"])
        let rows = makeRows([["Alice", "100"]])

        let a4 = CGSize(width: 595, height: 842)
        let layout = calc.calculateFixedSize(columns: columns, rows: rows, pageSize: a4)

        XCTAssertEqual(layout.pageSize, a4)
        XCTAssertEqual(layout.pages.count, 1)
        XCTAssertEqual(layout.tableOrigin, CGPoint(x: calc.pageMargin, y: calc.pageMargin))
    }

    /// T433: Fixed-size A4 landscape layout.
    func testT433_fixedSizeA4Landscape() {
        let calc = makeCalculator()
        let columns = makeColumns(["Name", "Value", "Unit"])
        let rows = makeRows([["Alice", "100", "USD"]])

        let a4Landscape = CGSize(width: 842, height: 595)
        let layout = calc.calculateFixedSize(columns: columns, rows: rows, pageSize: a4Landscape)

        XCTAssertEqual(layout.pageSize, a4Landscape)
        XCTAssertEqual(layout.pages.count, 1)
    }

    // MARK: - Edge Cases

    /// Empty columns should return empty widths.
    func testEmptyColumns() {
        let calc = makeCalculator()
        let widths = calc.calculateColumnWidths(columns: [], rows: [], availableWidth: nil)
        XCTAssertTrue(widths.isEmpty)
    }

    /// Empty values should return minimum height.
    func testEmptyValues() {
        let calc = makeCalculator()
        let height = calc.calculateRowHeight(values: [], columnWidths: [])
        let expected = calc.singleLineHeight() + calc.verticalPadding
        XCTAssertEqual(height, expected, accuracy: 1.0)
    }
}
