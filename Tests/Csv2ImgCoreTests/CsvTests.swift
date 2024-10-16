import XCTest

@testable import Csv2ImgCore

final class Csv2Tests: XCTestCase {
    func testCsvParseFromString() async {
        let input = """
            name,beginnerValue,middleValue,expertValue,unit
            Requirements Analysis,1.00,1.00,1.00,H
            Concept Design,0.10,0.50,1.00,H
            Detail Design,0.10,0.50,1.00,page
            Graphic Design,0.00,0.10,0.25,item
            HTML Coding,50.00,80.00,100.00,step
            Review,1.00,1.00,1.00,H
            Test,0.50,1.00,1.00,H
            Release,1.00,1.00,1.00,H
            """
        let styles = [
            Csv.Column.Style(color: Color.red.cgColor, applyOnlyColumn: false),
            Csv.Column.Style(color: Color.black.cgColor, applyOnlyColumn: false),
            Csv.Column.Style(color: Color.green.cgColor, applyOnlyColumn: false),
            Csv.Column.Style(color: Color.blue.cgColor, applyOnlyColumn: false),
            Csv.Column.Style(color: Color.yellow.cgColor, applyOnlyColumn: false),
        ]
        let csv = Csv.loadFromString(input, styles: styles)
        let actualColumns = await csv.columns
        let actualRows = await csv.rows
        XCTAssertEqual(
            actualColumns,
            [
                Csv.Column(
                    name: "name",
                    style: styles[0]
                ),
                Csv.Column(
                    name: "beginnerValue",
                    style: styles[1]
                ),
                Csv.Column(
                    name: "middleValue",
                    style: styles[2]
                ),
                Csv.Column(
                    name: "expertValue",
                    style: styles[3]
                ),
                Csv.Column(
                    name: "unit",
                    style: styles[4]
                ),
            ]
        )
        XCTAssertEqual(
            actualRows,
            [
                .init(index: 1, values: ["Requirements Analysis", "1.00", "1.00", "1.00", "H"]),
                .init(index: 2, values: ["Concept Design", "0.10", "0.50", "1.00", "H"]),
                .init(index: 3, values: ["Detail Design", "0.10", "0.50", "1.00", "page"]),
                .init(index: 4, values: ["Graphic Design", "0.00", "0.10", "0.25", "item"]),
                .init(index: 5, values: ["HTML Coding", "50.00", "80.00", "100.00", "step"]),
                .init(index: 6, values: ["Review", "1.00", "1.00", "1.00", "H"]),
                .init(index: 7, values: ["Test", "0.50", "1.00", "1.00", "H"]),
                .init(index: 8, values: ["Release", "1.00", "1.00", "1.00", "H"]),
            ]
        )
    }
}
