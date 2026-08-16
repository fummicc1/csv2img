import XCTest

@testable import Csv2ImgCore

final class PerformanceTests: XCTestCase {

    /// P001: Parse 10,000 rows within acceptable time.
    func testP001_parseLargeCSV() throws {
        var lines = ["col1,col2,col3,col4,col5"]
        for i in 0..<10_000 {
            lines.append("value\(i),data\(i),item\(i),extra\(i),end\(i)")
        }
        let input = lines.joined(separator: "\n")
        let parser = CsvParser()

        let start = CFAbsoluteTimeGetCurrent()
        let result = try parser.parse(input)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(result.rows.count, 10_000)
        XCTAssertLessThan(elapsed, 5.0, "Parsing 10K rows should complete within 5 seconds, took \(elapsed)s")
    }

    /// P002: SeparatorDetector on large input.
    func testP002_separatorDetectorPerformance() {
        var lines = [String]()
        for i in 0..<1_000 {
            lines.append("a\(i),b\(i),c\(i)")
        }
        let input = lines.joined(separator: "\n")
        let detector = SeparatorDetector()

        let start = CFAbsoluteTimeGetCurrent()
        let sep = detector.detect(from: input)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(sep, ",")
        XCTAssertLessThan(elapsed, 1.0, "Separator detection should complete within 1 second")
    }

    /// P003: PDF generation with 100 rows in A4.
    func testP003_pdfGenerationPerformance() throws {
        let columns = Csv.Column.Style.random(count: 5).enumerated().map { (i, style) in
            Csv.Column(name: "Column\(i)", style: style)
        }
        let rows = (0..<100).map { i in
            Csv.Row(index: i + 1, values: ["Data\(i)", "More\(i)", "Value\(i)", "Extra\(i)", "End\(i)"])
        }
        let pdfMaker = PdfMaker(
            maximumRowCount: nil,
            fontSize: 12,
            metadata: PDFMetadata(size: .a4, orientation: .portrait)
        )

        let start = CFAbsoluteTimeGetCurrent()
        let pdf = try pdfMaker.make(columns: columns, rows: rows) { _ in }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertGreaterThan(pdf.pageCount, 0)
        XCTAssertLessThan(elapsed, 10.0, "PDF generation for 100 rows should complete within 10 seconds, took \(elapsed)s")
    }
}
