import XCTest

@testable import Csv2ImgCore

final class PDFMetadataTests: XCTestCase {

    /// T601: Default initialization preserves backward compatibility.
    func testT601_defaultInit() {
        let metadata = PDFMetadata()
        XCTAssertNil(metadata.author)
        XCTAssertNil(metadata.title)
        XCTAssertNil(metadata.size)
        XCTAssertEqual(metadata.orientation, .portrait)
        XCTAssertNil(metadata.subject)
        XCTAssertNil(metadata.keywords)
        XCTAssertNil(metadata.creationDate)
        XCTAssertEqual(metadata.creator, "Csv2Img")
    }

    /// T602: Existing parameters only — new properties get defaults.
    func testT602_existingParamsOnly() {
        let metadata = PDFMetadata(author: "Alice", title: "Report")
        XCTAssertEqual(metadata.author, "Alice")
        XCTAssertEqual(metadata.title, "Report")
        XCTAssertNil(metadata.subject)
        XCTAssertNil(metadata.keywords)
        XCTAssertNil(metadata.creationDate)
        XCTAssertEqual(metadata.creator, "Csv2Img")
    }

    /// T603: All parameters specified.
    func testT603_allParams() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let metadata = PDFMetadata(
            author: "Bob",
            title: "Data",
            size: .a4,
            orientation: .landscape,
            subject: "Test Subject",
            keywords: ["csv", "table"],
            creationDate: date,
            creator: "MyApp"
        )
        XCTAssertEqual(metadata.author, "Bob")
        XCTAssertEqual(metadata.title, "Data")
        XCTAssertEqual(metadata.size, .a4)
        XCTAssertEqual(metadata.orientation, .landscape)
        XCTAssertEqual(metadata.subject, "Test Subject")
        XCTAssertEqual(metadata.keywords, ["csv", "table"])
        XCTAssertEqual(metadata.creationDate, date)
        XCTAssertEqual(metadata.creator, "MyApp")
    }
}
