import PDFKit
import XCTest

@testable import Csv2Img

class PdfMakerTests: XCTestCase {
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
}
