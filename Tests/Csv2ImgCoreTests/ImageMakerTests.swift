import XCTest

@testable import Csv2ImgCore

class ImageMakerTests: XCTestCase {
    func testBuildImage() async throws {
        // Given
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
        let expectedImageRepresentation = CsvImageRepresentation(
            width: 546,
            height: 160,
            backgroundColor: CGColor(red: 0.980392, green: 0.980392, blue: 0.980392, alpha: 1),
            fontSize: 12.0,
            columns: [
                CsvImageRepresentation.ColumnRepresentation(
                    name: "name",
                    style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                    frame: CGRect(x: 8.0, y: 12.0, width: 158.0, height: 25.0)),
                CsvImageRepresentation.ColumnRepresentation(
                    name: "beginnerValue",
                    style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                    frame: CGRect(x: 174.0, y: 12.0, width: 106.0, height: 25.0)),
                CsvImageRepresentation.ColumnRepresentation(
                    name: "middleValue",
                    style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                    frame: CGRect(x: 288.0, y: 12.0, width: 93.0, height: 25.0)),
                CsvImageRepresentation.ColumnRepresentation(
                    name: "expertValue",
                    style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                    frame: CGRect(x: 389.0, y: 12.0, width: 92.0, height: 25.0)),
                CsvImageRepresentation.ColumnRepresentation(
                    name: "unit",
                    style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                    frame: CGRect(x: 489.0, y: 12.0, width: 49.0, height: 25.0)),
            ],
            rows: [
                CsvImageRepresentation.RowRepresentation(
                    values: ["Requirements Analysis", "1.00", "1.00", "1.00", "H"],
                    frames: [
                        CGRect(x: 8.0, y: 49.0, width: 158.0, height: 25.0),
                        CGRect(x: 174.0, y: 49.0, width: 106.0, height: 25.0),
                        CGRect(x: 288.0, y: 49.0, width: 93.0, height: 25.0),
                        CGRect(x: 389.0, y: 49.0, width: 92.0, height: 25.0),
                        CGRect(x: 489.0, y: 49.0, width: 49.0, height: 25.0),
                    ]),
                CsvImageRepresentation.RowRepresentation(
                    values: ["Concept Design", "0.10", "0.50", "1.00", "H"],
                    frames: [
                        CGRect(x: 8.0, y: 86.0, width: 158.0, height: 25.0),
                        CGRect(x: 174.0, y: 86.0, width: 106.0, height: 25.0),
                        CGRect(x: 288.0, y: 86.0, width: 93.0, height: 25.0),
                        CGRect(x: 389.0, y: 86.0, width: 92.0, height: 25.0),
                        CGRect(x: 489.0, y: 86.0, width: 49.0, height: 25.0),
                    ]),
                CsvImageRepresentation.RowRepresentation(
                    values: ["Detail Design", "0.10", "0.50", "1.00", "page"],
                    frames: [
                        CGRect(x: 8.0, y: 123.0, width: 158.0, height: 25.0),
                        CGRect(x: 174.0, y: 123.0, width: 106.0, height: 25.0),
                        CGRect(x: 288.0, y: 123.0, width: 93.0, height: 25.0),
                        CGRect(x: 389.0, y: 123.0, width: 92.0, height: 25.0),
                        CGRect(x: 489.0, y: 123.0, width: 49.0, height: 25.0),
                    ]),
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
        XCTAssertEqual(imageRepresentation.width, expectedImageRepresentation.width)
        XCTAssertEqual(imageRepresentation.height, expectedImageRepresentation.height)
        XCTAssertEqual(imageRepresentation.fontSize, expectedImageRepresentation.fontSize)

        // background colors
        XCTAssertEqual(
            imageRepresentation.backgroundColor.components?.count,
            expectedImageRepresentation.backgroundColor.components?.count
        )

        if let actualComponents = imageRepresentation.backgroundColor.components,
            let expectedComponents = expectedImageRepresentation.backgroundColor.components
        {
            for (actual, expected) in zip(actualComponents, expectedComponents) {
                // allow 0.0001 difference
                XCTAssertEqual(actual, expected, accuracy: 0.0001)
            }
        }

        // columns
        XCTAssertEqual(imageRepresentation.columns.count, expectedImageRepresentation.columns.count)
        for (actual, expected) in zip(
            imageRepresentation.columns, expectedImageRepresentation.columns)
        {
            XCTAssertEqual(actual.name, expected.name)
            XCTAssertEqual(actual.frame, expected.frame)
            XCTAssertEqual(actual.style.color.components, expected.style.color.components)
        }

        // rows
        XCTAssertEqual(imageRepresentation.rows.count, expectedImageRepresentation.rows.count)
        for (actual, expected) in zip(imageRepresentation.rows, expectedImageRepresentation.rows) {
            XCTAssertEqual(actual.values, expected.values)
            XCTAssertEqual(actual.frames, expected.frames)
        }
    }
}
