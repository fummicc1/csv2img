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

/// Baseline measurements for the optimisation work. Skipped unless `CSV2IMG_BENCH` is set,
/// because the larger sizes take far longer than a regular test run should.
final class BenchmarkTests: XCTestCase {

    private static let columnCount = 5

    private func skipUnlessEnabled() throws -> [Int] {
        guard let raw = ProcessInfo.processInfo.environment["CSV2IMG_BENCH"] else {
            throw XCTSkip("Set CSV2IMG_BENCH to a comma-separated list of row counts to run benchmarks")
        }
        return raw.split(separator: ",").compactMap { Int($0) }
    }

    private func makeColumns() -> [Csv.Column] {
        Csv.Column.Style.random(count: Self.columnCount).enumerated().map { (i, style) in
            Csv.Column(name: "Column\(i)", style: style)
        }
    }

    private func makeRows(_ count: Int) -> [Csv.Row] {
        (0..<count).map { i in
            Csv.Row(index: i + 1, values: ["Data\(i)", "More\(i)", "Value\(i)", "Extra\(i)", "End\(i)"])
        }
    }

    private func measureOnce(_ label: String, rows: Int, _ body: () throws -> Void) rethrows {
        let start = CFAbsoluteTimeGetCurrent()
        try body()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print("BENCH\t\(label)\t\(rows)\t\(String(format: "%.3f", elapsed))")
    }

    func testBenchParse() throws {
        for count in try skipUnlessEnabled() {
            var lines = ["col1,col2,col3,col4,col5"]
            for i in 0..<count {
                lines.append("value\(i),data\(i),item\(i),extra\(i),end\(i)")
            }
            let input = lines.joined(separator: "\n")
            try measureOnce("parse", rows: count) {
                _ = try CsvParser().parse(input)
            }
        }
    }

    func testBenchImageLayout() throws {
        for count in try skipUnlessEnabled() {
            let columns = makeColumns()
            let rows = makeRows(count)
            let maker = ImageMaker(maximumRowCount: nil, fontSize: 12)
            try measureOnce("png-layout", rows: count) {
                _ = try maker.build(columns: columns, rows: rows) { _ in }
            }
        }
    }

    func testBenchImageRender() throws {
        let limit = Int(ProcessInfo.processInfo.environment["CSV2IMG_BENCH_PNG_MAX"] ?? "") ?? 1_000
        for count in try skipUnlessEnabled() where count <= limit {
            let columns = makeColumns()
            let rows = makeRows(count)
            let maker = ImageMaker(maximumRowCount: nil, fontSize: 12)
            try measureOnce("png-make", rows: count) {
                _ = try maker.make(columns: columns, rows: rows) { _ in }
            }
        }
    }

    func testBenchPdfFixedSize() throws {
        for count in try skipUnlessEnabled() {
            let columns = makeColumns()
            let rows = makeRows(count)
            let maker = PdfMaker(
                maximumRowCount: nil,
                fontSize: 12,
                metadata: PDFMetadata(size: .a4, orientation: .portrait)
            )
            try measureOnce("pdf-a4", rows: count) {
                _ = try maker.make(columns: columns, rows: rows) { _ in }
            }
        }
    }

    func testBenchPdfAutoSize() throws {
        for count in try skipUnlessEnabled() {
            let columns = makeColumns()
            let rows = makeRows(count)
            let maker = PdfMaker(
                maximumRowCount: nil,
                fontSize: 12,
                metadata: PDFMetadata(size: nil, orientation: .portrait)
            )
            try measureOnce("pdf-auto", rows: count) {
                _ = try maker.make(columns: columns, rows: rows) { _ in }
            }
        }
    }
}
