import XCTest

@testable import Csv2ImgCore

class ImageMakerTests: XCTestCase {
    func testBuildImage() async throws {
        // Given
        let fileURL = getRelativeFilePathFromPackageSource(
            path: "/Fixtures/outputs/category.png"
        )
        let csv = Csv.loadFromString(
            """
            name,beginnerValue,middleValue
            Requirements Analysis,1.00,1
            """,
            styles: [
                Csv.Column.Style(color: Color.blue.cgColor),
                Csv.Column.Style(color: Color.blue.cgColor),
                Csv.Column.Style(color: Color.blue.cgColor),
            ]
        )
        let imageMaker = ImageMaker(maximumRowCount: nil, fontSize: 12)
        let columns = await csv.columns
        let rows = await csv.rows
        // When
        let imageRepresentation = try imageMaker.build(
            columns: columns,
            rows: rows
        ) { double in
        }
        // Then
        print(imageRepresentation)
        let cgImage = try imageMaker.make(
            columns: columns,
            rows: rows
        ) { _ in
        }
        try cgImage.convertToData()?.write(to: fileURL)
    }
}
