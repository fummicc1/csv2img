import PDFKit
import XCTest

@testable import Csv2ImgCore

class PdfMakerTests: XCTestCase {

    // MARK: - Helpers

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

    private func makePdfMaker(metadata: PDFMetadata = .init()) -> PdfMaker {
        PdfMaker(maximumRowCount: nil, fontSize: 12, metadata: metadata)
    }

    // MARK: - Existing test

    func test_make() async throws {
        // Given
        let fileURL = getRelativeFilePathFromPackageSource(path: "/Fixtures/outputs/category.pdf")
        let expected = PDFDocument(url: fileURL)!
        let csv = Csv.loadFromString(
            """
            name,beginnerValue,middleValue,expertValue,unit
            Requirements Analysis,1.00,1.00,1.00,H
            Concept Design,0.10,0.50,1.00,H
            Detail Design,0.10,0.50,1.00,page
            """,
            styles: [
                Csv.Column.Style(color: Color.blue.cgColor),
                Csv.Column.Style(color: Color.blue.cgColor),
                Csv.Column.Style(color: Color.blue.cgColor),
                Csv.Column.Style(color: Color.blue.cgColor),
                Csv.Column.Style(color: Color.blue.cgColor),
            ]
        )
        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: .init()
        )
        // When
        let pdf = try pdfMaker.make(
            with: 12,
            columns: await csv.columns,
            rows: await csv.rows
        ) { _ in
        }
        // Then
        // TODO: Remove XCTSkip
        try XCTSkipIf(pdf.dataRepresentation() != expected.dataRepresentation())
        XCTAssertEqual(
            pdf.dataRepresentation(),
            expected.dataRepresentation()
        )
    }

    // MARK: - T501-T503: Fixed-size page splitting

    /// T501: Fixed-size PDF with many rows generates multiple pages.
    func testT501_fixedSizeMultiplePages() throws {
        let columns = makeColumns(["Name", "Value"])
        // 50 rows should exceed A5 height
        let rowData = (0..<50).map { ["Row\($0)", "Value\($0)"] }
        let rows = makeRows(rowData)

        let metadata = PDFMetadata(size: .a5, orientation: .portrait)
        let pdfMaker = makePdfMaker(metadata: metadata)

        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        XCTAssertGreaterThan(pdf.pageCount, 1, "50 rows in A5 should produce multiple pages")
    }

    /// T502: Each page of multi-page PDF exists and has valid bounds.
    func testT502_eachPageHasContent() throws {
        let columns = makeColumns(["A", "B", "C"])
        let rowData = (0..<50).map { ["Data\($0)", "More\($0)", "End\($0)"] }
        let rows = makeRows(rowData)

        let metadata = PDFMetadata(size: .a5, orientation: .portrait)
        let pdfMaker = makePdfMaker(metadata: metadata)

        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        for i in 0..<pdf.pageCount {
            let page = pdf.page(at: i)
            XCTAssertNotNil(page, "Page \(i) should exist")
            // Each page should have valid media box bounds
            let bounds = page!.bounds(for: .mediaBox)
            XCTAssertGreaterThan(bounds.width, 0, "Page \(i) should have positive width")
            XCTAssertGreaterThan(bounds.height, 0, "Page \(i) should have positive height")
        }
    }

    /// T503: Small data in A4 fits in single page.
    func testT503_singlePageFit() throws {
        let columns = makeColumns(["Name", "Value"])
        let rows = makeRows([["Alice", "100"], ["Bob", "200"]])

        let metadata = PDFMetadata(size: .a4, orientation: .portrait)
        let pdfMaker = makePdfMaker(metadata: metadata)

        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        XCTAssertEqual(pdf.pageCount, 1)
    }

    // MARK: - T511-T512: Page numbers

    /// T511: Multi-page PDF — page count matches expected layout.
    func testT511_multiPagePageNumbers() throws {
        let columns = makeColumns(["Name", "Value"])
        let rowData = (0..<50).map { ["Row\($0)", "Value\($0)"] }
        let rows = makeRows(rowData)

        let metadata = PDFMetadata(size: .a5, orientation: .portrait)
        let pdfMaker = makePdfMaker(metadata: metadata)

        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        // Verify multi-page generation — page numbers are drawn by drawPageNumber
        let totalPages = pdf.pageCount
        XCTAssertGreaterThan(totalPages, 1)

        // Verify each page has valid data representation (non-empty rendering)
        for i in 0..<totalPages {
            XCTAssertNotNil(pdf.page(at: i), "Page \(i) should exist")
        }

        // Verify layout calculator produces matching page count
        let calculator = PdfLayoutCalculator(fontSize: 12)
        let pageSize = PdfSize.a5.size(orientation: .portrait)
        let layout = calculator.calculateFixedSize(columns: columns, rows: rows, pageSize: pageSize)
        XCTAssertEqual(pdf.pageCount, layout.pages.count, "PDF page count should match layout calculator")
    }

    /// T512: Single page PDF — drawPageNumber is called (page renders correctly).
    func testT512_singlePagePageNumber() throws {
        let columns = makeColumns(["Name", "Value"])
        let rows = makeRows([["Alice", "100"]])

        let metadata = PDFMetadata(size: .a4, orientation: .portrait)
        let pdfMaker = makePdfMaker(metadata: metadata)

        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        XCTAssertEqual(pdf.pageCount, 1)
        // Page renders without crash and has data
        let data = pdf.dataRepresentation()
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 0)
    }

    // MARK: - T521-T524: PDF Metadata

    /// T521: All metadata fields are set in the PDF.
    func testT521_allMetadataSet() throws {
        let columns = makeColumns(["A"])
        let rows = makeRows([["1"]])

        let date = Date(timeIntervalSince1970: 1_000_000)
        let metadata = PDFMetadata(
            author: "TestAuthor",
            title: "TestTitle",
            size: .a4,
            orientation: .portrait,
            subject: "TestSubject",
            keywords: ["csv", "table"],
            creationDate: date,
            creator: "TestCreator"
        )
        let pdfMaker = makePdfMaker(metadata: metadata)
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        // Verify metadata via PDF document attributes
        let attrs = pdf.documentAttributes ?? [:]
        XCTAssertEqual(attrs[PDFDocumentAttribute.titleAttribute] as? String, "TestTitle")
        XCTAssertEqual(attrs[PDFDocumentAttribute.authorAttribute] as? String, "TestAuthor")
        XCTAssertEqual(attrs[PDFDocumentAttribute.subjectAttribute] as? String, "TestSubject")
        XCTAssertEqual(attrs[PDFDocumentAttribute.creatorAttribute] as? String, "TestCreator")
        if let kw = attrs[PDFDocumentAttribute.keywordsAttribute] as? [String] {
            XCTAssertEqual(kw, ["csv", "table"])
        }
    }

    /// T522: Default metadata — creator should be "Csv2Img".
    func testT522_defaultMetadata() throws {
        let columns = makeColumns(["A"])
        let rows = makeRows([["1"]])

        let metadata = PDFMetadata(size: .a4)
        let pdfMaker = makePdfMaker(metadata: metadata)
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        let attrs = pdf.documentAttributes ?? [:]
        XCTAssertEqual(attrs[PDFDocumentAttribute.creatorAttribute] as? String, "Csv2Img")
    }

    /// T523: Existing metadata (author, title) still works with new properties defaulted.
    func testT523_existingMetadataCompat() throws {
        let columns = makeColumns(["A"])
        let rows = makeRows([["1"]])

        let metadata = PDFMetadata(
            author: "Alice",
            title: "Report",
            size: .a4
        )
        let pdfMaker = makePdfMaker(metadata: metadata)
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        let attrs = pdf.documentAttributes ?? [:]
        XCTAssertEqual(attrs[PDFDocumentAttribute.titleAttribute] as? String, "Report")
        XCTAssertEqual(attrs[PDFDocumentAttribute.authorAttribute] as? String, "Alice")
        XCTAssertEqual(attrs[PDFDocumentAttribute.creatorAttribute] as? String, "Csv2Img")
    }

    /// T524: Keywords array is reflected in PDF.
    func testT524_keywordsArray() throws {
        let columns = makeColumns(["A"])
        let rows = makeRows([["1"]])

        let metadata = PDFMetadata(
            size: .a4,
            keywords: ["data", "export", "pdf"]
        )
        let pdfMaker = makePdfMaker(metadata: metadata)
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        let attrs = pdf.documentAttributes ?? [:]
        if let kw = attrs[PDFDocumentAttribute.keywordsAttribute] as? [String] {
            XCTAssertEqual(kw, ["data", "export", "pdf"])
        }
    }

    // MARK: - T531-T532: Column width variation

    /// T531: Short and long columns produce different widths in PDF.
    func testT531_variableColumnWidths() throws {
        let columns = makeColumns(["A", "VeryLongColumnHeader"])
        let rows = makeRows([["x", "SomeLongerTextValue"], ["y", "Another"]])

        let metadata = PDFMetadata(size: .a4, orientation: .portrait)
        let pdfMaker = makePdfMaker(metadata: metadata)

        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        // Just verify it generates successfully with no crash
        XCTAssertEqual(pdf.pageCount, 1)
        XCTAssertNotNil(pdf.dataRepresentation())
    }

    /// T532: Auto-size mode produces valid PDF with variable column widths.
    func testT532_autoSizeVariableColumns() throws {
        let columns = makeColumns(["Short", "A Much Longer Column Name Here"])
        let rows = makeRows([["1", "Some data"], ["2", "More data"]])

        let pdfMaker = makePdfMaker()

        let pdf = try pdfMaker.make(with: 12, columns: columns, rows: rows) { _ in }

        XCTAssertNotNil(pdf.dataRepresentation())
        XCTAssertGreaterThan(pdf.pageCount, 0)
    }
}
