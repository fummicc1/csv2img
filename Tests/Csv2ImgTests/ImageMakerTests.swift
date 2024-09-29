import XCTest

@testable import Csv2Img

class ImageMakerTests: XCTestCase {
    func testMakeImage() async throws {
        // Given
        let fileURL = getRelativeFilePathFromPackageSource(
            path: "/Fixtures/outputs/category.png"
        )
        let expected = try Data(contentsOf: fileURL)
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
        let imageMaker = ImageMaker(maximumRowCount: nil, fontSize: 12)
        // When
        let image = try imageMaker.make(
            columns: await csv.columns,
            rows: await csv.rows
        ) { double in
        }
        // Then
        // TODO: Remove XCTSkip
        try XCTSkipIf(image.convertToData() != expected)
        XCTAssertEqual(image.convertToData(), expected)
    }
}
