import PDFKit
import XCTest

@testable import Csv2ImgCore

/// Integration tests covering end-to-end scenarios from CSV parsing through PDF generation.
final class IntegrationTests: XCTestCase {

    // MARK: - T701-T706: Csv backward compatibility + new features

    /// T701: Existing Csv.loadFromString behavior preserved.
    func testT701_existingBehaviorPreserved() async {
        let input = """
            name,value,unit
            Alpha,1.00,H
            Beta,2.00,page
            """
        let csv = Csv.loadFromString(input)
        let columns = await csv.columns
        let rows = await csv.rows
        XCTAssertEqual(columns.count, 3)
        XCTAssertEqual(columns.map(\.name), ["name", "value", "unit"])
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].values, ["Alpha", "1.00", "H"])
        XCTAssertEqual(rows[1].values, ["Beta", "2.00", "page"])
    }

    /// T702: Explicit separator is respected.
    func testT702_explicitSeparator() async {
        let input = "a;b;c\n1;2;3"
        let csv = Csv.loadFromString(input, separator: ";")
        let columns = await csv.columns
        let rows = await csv.rows
        XCTAssertEqual(columns.map(\.name), ["a", "b", "c"])
        XCTAssertEqual(rows[0].values, ["1", "2", "3"])
    }

    /// T705: Quoted CSV fields through to PDF generation.
    func testT705_quotedCsvToPdf() async throws {
        let input = """
            name,city
            John,"Tokyo, Japan"
            Jane,"New York, USA"
            """
        let csv = Csv.loadFromString(input, exportType: .pdf)
        let columns = await csv.columns
        let rows = await csv.rows

        // Verify parsing handles quotes correctly
        XCTAssertEqual(rows[0].values[1], "Tokyo, Japan")
        XCTAssertEqual(rows[1].values[1], "New York, USA")

        // Verify PDF generation succeeds
        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: PDFMetadata(size: .a4)
        )
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }
        XCTAssertEqual(pdf.pageCount, 1)
    }

    /// T706: Japanese CSV through to PDF generation.
    func testT706_japaneseCsvToPdf() async throws {
        let input = "名前,年齢,都市\n太郎,30,東京\n花子,25,大阪"
        let csv = Csv.loadFromString(input, exportType: .pdf)
        let columns = await csv.columns
        let rows = await csv.rows

        XCTAssertEqual(columns.map(\.name), ["名前", "年齢", "都市"])
        XCTAssertEqual(rows[0].values, ["太郎", "30", "東京"])

        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: PDFMetadata(size: .a4)
        )
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }
        XCTAssertEqual(pdf.pageCount, 1)
    }

    // MARK: - Scenario 1: Excel-style CSV → PDF

    func testScenario1_excelCsvToPdf() async throws {
        // Excel-style CSV with CRLF, Japanese, and quoted fields
        let input = "商品名,価格,説明\r\n\"りんご\",\"¥100\",\"青森産の\"\"ふじ\"\"\"\r\n\"みかん\",\"¥80\",\"愛媛産\"\r\n\"バナナ\",\"¥150\",\"フィリピン産\""

        let csv = Csv.loadFromString(input, exportType: .pdf)
        let columns = await csv.columns
        let rows = await csv.rows

        XCTAssertEqual(columns.count, 3)
        XCTAssertEqual(columns.map(\.name), ["商品名", "価格", "説明"])
        XCTAssertEqual(rows.count, 3)
        // Double-quote escape: ""ふじ"" → "ふじ"
        XCTAssertEqual(rows[0].values[2], "青森産の\"ふじ\"")

        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: PDFMetadata(size: .a4, orientation: .portrait)
        )
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }
        XCTAssertGreaterThanOrEqual(pdf.pageCount, 1)
    }

    // MARK: - Scenario 2: Column count mismatch → warning + PDF

    func testScenario2_columnMismatchToPdf() async throws {
        // Row 2 has fewer fields, row 3 has more
        let input = "a,b,c\n1,2,3\n4\n5,6,7,8"

        let parser = CsvParser()
        let result = try parser.parse(input)

        // Verify warnings
        XCTAssertEqual(result.warnings.count, 2)
        // Row with fewer fields is padded
        XCTAssertEqual(result.rows[1].values, ["4", "", ""])
        // Row with more fields is truncated
        XCTAssertEqual(result.rows[2].values, ["5", "6", "7"])

        // Generate PDF from parsed data
        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: PDFMetadata(size: .a4)
        )
        let pdf = try pdfMaker.make(columns: result.columns, rows: result.rows) { _ in }
        XCTAssertEqual(pdf.pageCount, 1)
    }

    // MARK: - Scenario 3: Large data → multi-page PDF

    func testScenario3_largeDataMultiPagePdf() async throws {
        // 100 rows × 5 columns
        var lines = ["name,col2,col3,col4,col5"]
        for i in 0..<100 {
            lines.append("Row\(i),Data\(i),Value\(i),Extra\(i),End\(i)")
        }
        let input = lines.joined(separator: "\n")

        let csv = Csv.loadFromString(input, exportType: .pdf)
        let columns = await csv.columns
        let rows = await csv.rows

        XCTAssertEqual(columns.count, 5)
        XCTAssertEqual(rows.count, 100)

        let metadata = PDFMetadata(
            author: "Integration Test",
            title: "Large Data",
            size: .a4,
            orientation: .portrait,
            subject: "Test",
            creator: "Csv2Img"
        )
        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: metadata
        )
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }

        XCTAssertGreaterThan(pdf.pageCount, 1, "100 rows in A4 should produce multiple pages")

        // Verify metadata
        let attrs = pdf.documentAttributes ?? [:]
        XCTAssertEqual(attrs[PDFDocumentAttribute.authorAttribute] as? String, "Integration Test")
        XCTAssertEqual(attrs[PDFDocumentAttribute.titleAttribute] as? String, "Large Data")
    }

    // MARK: - Security: Malicious input resilience

    func testSecurity_scriptInjectionInFields() async throws {
        let input = "name,value\n<script>alert('xss')</script>,normal"
        let csv = Csv.loadFromString(input, exportType: .pdf)
        let rows = await csv.rows

        // Script tags are treated as plain text
        XCTAssertEqual(rows[0].values[0], "<script>alert('xss')</script>")

        // PDF generation should succeed without executing scripts
        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: PDFMetadata(size: .a4)
        )
        let columns = await csv.columns
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }
        XCTAssertNotNil(pdf.dataRepresentation())
    }
}
