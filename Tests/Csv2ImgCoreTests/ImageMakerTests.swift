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
        let expectedImageRepresentation: CsvImageRepresentation
        #if os(iOS)
            expectedImageRepresentation = CsvImageRepresentation(
                width: 500,
                height: 152,
                backgroundColor: CGColor(red: 0.980392, green: 0.980392, blue: 0.980392, alpha: 1),
                fontSize: 12.0,
                columns: [
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "name",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 8.0, y: 12.0, width: 142.0, height: 23.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "beginnerValue",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 158.0, y: 12.0, width: 96.0, height: 23.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "middleValue",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 262.0, y: 12.0, width: 85.0, height: 23.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "expertValue",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 355.0, y: 12.0, width: 83.0, height: 23.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "unit",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 446.0, y: 12.0, width: 46.0, height: 23.0)),
                ],
                rows: [
                    CsvImageRepresentation.RowRepresentation(
                        values: ["Requirements Analysis", "1.00", "1.00", "1.00", "H"],
                        frames: [
                            CGRect(x: 8.0, y: 47.0, width: 142.0, height: 23.0),
                            CGRect(x: 158.0, y: 47.0, width: 96.0, height: 23.0),
                            CGRect(x: 262.0, y: 47.0, width: 85.0, height: 23.0),
                            CGRect(x: 355.0, y: 47.0, width: 83.0, height: 23.0),
                            CGRect(x: 446.0, y: 47.0, width: 46.0, height: 23.0),
                        ]),
                    CsvImageRepresentation.RowRepresentation(
                        values: ["Concept Design", "0.10", "0.50", "1.00", "H"],
                        frames: [
                            CGRect(x: 8.0, y: 82.0, width: 142.0, height: 23.0),
                            CGRect(x: 158.0, y: 82.0, width: 96.0, height: 23.0),
                            CGRect(x: 262.0, y: 82.0, width: 85.0, height: 23.0),
                            CGRect(x: 355.0, y: 82.0, width: 83.0, height: 23.0),
                            CGRect(x: 446.0, y: 82.0, width: 46.0, height: 23.0),
                        ]),
                    CsvImageRepresentation.RowRepresentation(
                        values: ["Detail Design", "0.10", "0.50", "1.00", "page"],
                        frames: [
                            CGRect(x: 8.0, y: 117.0, width: 142.0, height: 23.0),
                            CGRect(x: 158.0, y: 117.0, width: 96.0, height: 23.0),
                            CGRect(x: 262.0, y: 117.0, width: 85.0, height: 23.0),
                            CGRect(x: 355.0, y: 117.0, width: 83.0, height: 23.0),
                            CGRect(x: 446.0, y: 117.0, width: 46.0, height: 23.0),
                        ]),
                ]
            )
        #elseif os(macOS)
            expectedImageRepresentation = CsvImageRepresentation(
                width: 500,
                height: 148,
                backgroundColor: CGColor(red: 0.980392, green: 0.980392, blue: 0.980392, alpha: 1),
                fontSize: 12.0,
                columns: [
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "name",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 8.0, y: 12.0, width: 142.0, height: 22.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "beginnerValue",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 158.0, y: 12.0, width: 96.0, height: 22.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "middleValue",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 262.0, y: 12.0, width: 85.0, height: 22.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "expertValue",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 355.0, y: 12.0, width: 83.0, height: 22.0)),
                    CsvImageRepresentation.ColumnRepresentation(
                        name: "unit",
                        style: Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
                        frame: CGRect(x: 446.0, y: 12.0, width: 46.0, height: 22.0)),
                ],
                rows: [
                    CsvImageRepresentation.RowRepresentation(
                        values: ["Requirements Analysis", "1.00", "1.00", "1.00", "H"],
                        frames: [
                            CGRect(x: 8.0, y: 46.0, width: 142.0, height: 22.0),
                            CGRect(x: 158.0, y: 46.0, width: 96.0, height: 22.0),
                            CGRect(x: 262.0, y: 46.0, width: 85.0, height: 22.0),
                            CGRect(x: 355.0, y: 46.0, width: 83.0, height: 22.0),
                            CGRect(x: 446.0, y: 46.0, width: 46.0, height: 22.0),
                        ]),
                    CsvImageRepresentation.RowRepresentation(
                        values: ["Concept Design", "0.10", "0.50", "1.00", "H"],
                        frames: [
                            CGRect(x: 8.0, y: 80.0, width: 142.0, height: 22.0),
                            CGRect(x: 158.0, y: 80.0, width: 96.0, height: 22.0),
                            CGRect(x: 262.0, y: 80.0, width: 85.0, height: 22.0),
                            CGRect(x: 355.0, y: 80.0, width: 83.0, height: 22.0),
                            CGRect(x: 446.0, y: 80.0, width: 46.0, height: 22.0),
                        ]),
                    CsvImageRepresentation.RowRepresentation(
                        values: ["Detail Design", "0.10", "0.50", "1.00", "page"],
                        frames: [
                            CGRect(x: 8.0, y: 114.0, width: 142.0, height: 22.0),
                            CGRect(x: 158.0, y: 114.0, width: 96.0, height: 22.0),
                            CGRect(x: 262.0, y: 114.0, width: 85.0, height: 22.0),
                            CGRect(x: 355.0, y: 114.0, width: 83.0, height: 22.0),
                            CGRect(x: 446.0, y: 114.0, width: 46.0, height: 22.0),
                        ]),
                ]
            )
        #endif
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

    func testMakeImage() async throws {
        // Given
        let outputFileURL = getRelativeFilePathFromPackageSource(
            path: "Fixtures/outputs/category.png"
        )
        let csv = Csv.loadFromString(
            """
            name,beginnerValue,middleValue,expertValue,unit
            Requirements Analysis,1.00,1.00,1.00,H
            Concept Design,0.10,0.50,1.00,H
            Detail Design,0.10,0.50,1.00,page
            """
        )
        let imageMaker = ImageMaker(maximumRowCount: nil, fontSize: 12)
        let columns = await csv.columns
        let rows = await csv.rows
        // When
        let image = try imageMaker.make(columns: columns, rows: rows) { double in
        }
        // Then
        try image.convertToData()?.write(to: outputFileURL, options: .atomic)
    }
}
