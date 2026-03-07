import XCTest

@testable import Csv2ImgCore

final class CsvParserTests: XCTestCase {

    private let parser = CsvParser()

    // MARK: - Normal cases — RFC 4180

    /// T001: Simple CSV with 3 columns and 2 data rows.
    func testT001_simpleCsv() throws {
        let input = "a,b,c\n1,2,3\n4,5,6"
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.count, 3)
        XCTAssertEqual(result.columns.map(\.name), ["a", "b", "c"])
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0].values, ["1", "2", "3"])
        XCTAssertEqual(result.rows[1].values, ["4", "5", "6"])
        XCTAssertEqual(result.rows[0].index, 1)
        XCTAssertEqual(result.rows[1].index, 2)
    }

    /// T002: Quoted field containing a comma.
    func testT002_quotedFieldWithComma() throws {
        let input = "name,city\nJohn,\"Tokyo, Japan\""
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values[1], "Tokyo, Japan")
    }

    /// T003: Quoted field containing a newline.
    func testT003_quotedFieldWithNewline() throws {
        let input = "a,b\n\"line1\nline2\",val"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values[0], "line1\nline2")
        XCTAssertEqual(result.rows[0].values[1], "val")
    }

    /// T004: Double quote escape inside quoted field.
    func testT004_doubleQuoteEscape() throws {
        let input = "a\n\"He said \"\"hello\"\"\""
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values[0], "He said \"hello\"")
    }

    /// T005: Consecutive double quotes producing `""`.
    func testT005_consecutiveDoubleQuotes() throws {
        let input = "a\n\"\"\"\"\"\""
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values[0], "\"\"")
    }

    /// T006: Empty quoted field.
    func testT006_emptyQuotedField() throws {
        let input = "a\n\"\""
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values[0], "")
    }

    /// T007: CRLF inside a quoted field is preserved.
    func testT007_crlfInsideQuote() throws {
        let input = "a\n\"line1\r\nline2\""
        let result = try parser.parse(input)
        XCTAssertTrue(result.rows[0].values[0].contains("\r\n"))
        XCTAssertEqual(result.rows[0].values[0], "line1\r\nline2")
    }

    /// T008: Header only, no data rows.
    func testT008_headerOnly() throws {
        let input = "a,b,c"
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.count, 3)
        XCTAssertEqual(result.rows.count, 0)
    }

    /// T009: Trailing newline should not create an extra empty row.
    func testT009_trailingNewline() throws {
        let input = "a,b\n1,2\n"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0].values, ["1", "2"])
    }

    /// T010: All fields quoted.
    func testT010_allFieldsQuoted() throws {
        let input = "\"a\",\"b\"\n\"1\",\"2\""
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.map(\.name), ["a", "b"])
        XCTAssertEqual(result.rows[0].values, ["1", "2"])
    }

    // MARK: - Newline handling

    /// T011: LF newline.
    func testT011_lfNewline() throws {
        let input = "a,b\n1,2\n3,4"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0].values, ["1", "2"])
        XCTAssertEqual(result.rows[1].values, ["3", "4"])
    }

    /// T012: CRLF newline.
    func testT012_crlfNewline() throws {
        let input = "a,b\r\n1,2\r\n3,4"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0].values, ["1", "2"])
        XCTAssertEqual(result.rows[1].values, ["3", "4"])
    }

    /// T013: CR newline.
    func testT013_crNewline() throws {
        let input = "a,b\r1,2\r3,4"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0].values, ["1", "2"])
        XCTAssertEqual(result.rows[1].values, ["3", "4"])
    }

    /// T014: Mixed newlines (LF + CRLF).
    func testT014_mixedNewlines() throws {
        let input = "a,b\n1,2\r\n3,4"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0].values, ["1", "2"])
        XCTAssertEqual(result.rows[1].values, ["3", "4"])
    }

    // MARK: - Column count validation

    /// T017: Fewer fields in a row are padded with empty strings + warning.
    func testT017_fewerFieldsPadded() throws {
        let input = "a,b,c\n1"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values, ["1", "", ""])
        XCTAssertEqual(result.warnings.count, 1)
        if case .columnCountMismatch(let expected, let actual) = result.warnings[0].kind {
            XCTAssertEqual(expected, 3)
            XCTAssertEqual(actual, 1)
        } else {
            XCTFail("Expected columnCountMismatch warning")
        }
    }

    /// T018: More fields in a row are truncated + warning.
    func testT018_moreFieldsTruncated() throws {
        let input = "a,b\n1,2,3,4"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values, ["1", "2"])
        XCTAssertEqual(result.warnings.count, 1)
        if case .columnCountMismatch(let expected, let actual) = result.warnings[0].kind {
            XCTAssertEqual(expected, 2)
            XCTAssertEqual(actual, 4)
        } else {
            XCTFail("Expected columnCountMismatch warning")
        }
    }

    /// T020: All rows match column count — no warnings.
    func testT020_allRowsMatch() throws {
        let input = "a,b\n1,2\n3,4"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertTrue(result.warnings.isEmpty)
    }

    // MARK: - maxFieldLength

    /// T021: Field truncated when exceeding maxFieldLength.
    func testT021_fieldTruncated() throws {
        let input = "a\nHelloWorld"
        let options = CsvParser.Options(maxFieldLength: 5)
        let result = try parser.parse(input, options: options)
        XCTAssertEqual(result.rows[0].values[0], "He...")
        XCTAssertEqual(result.warnings.count, 1)
        if case .fieldTruncated(let originalLength, let maxLength) = result.warnings[0].kind {
            XCTAssertEqual(originalLength, 10)
            XCTAssertEqual(maxLength, 5)
        } else {
            XCTFail("Expected fieldTruncated warning")
        }
    }

    /// T022: Field within limit is not truncated.
    func testT022_fieldWithinLimit() throws {
        let input = "a\nHello"
        let options = CsvParser.Options(maxFieldLength: 10)
        let result = try parser.parse(input, options: options)
        XCTAssertEqual(result.rows[0].values[0], "Hello")
        XCTAssertTrue(result.warnings.isEmpty)
    }

    // MARK: - Error cases

    /// T101: Empty string throws emptyData.
    func testT101_emptyString() throws {
        XCTAssertThrowsError(try parser.parse("")) { error in
            guard case Csv.Error.emptyData = error else {
                XCTFail("Expected emptyData, got \(error)")
                return
            }
        }
    }

    /// T102: Whitespace-only string throws emptyData.
    func testT102_whitespaceOnly() throws {
        XCTAssertThrowsError(try parser.parse("   \n\t  \n  ")) { error in
            guard case Csv.Error.emptyData = error else {
                XCTFail("Expected emptyData, got \(error)")
                return
            }
        }
    }

    /// T103: Unclosed quote throws invalidQuoting.
    func testT103_unclosedQuote() throws {
        let input = "a\n\"unclosed"
        XCTAssertThrowsError(try parser.parse(input)) { error in
            guard case Csv.Error.invalidQuoting = error else {
                XCTFail("Expected invalidQuoting, got \(error)")
                return
            }
        }
    }

    /// T104: Invalid char after closing quote throws invalidQuoting.
    func testT104_invalidCharAfterClosingQuote() throws {
        let input = "a\n\"value\"x"
        XCTAssertThrowsError(try parser.parse(input)) { error in
            guard case Csv.Error.invalidQuoting = error else {
                XCTFail("Expected invalidQuoting, got \(error)")
                return
            }
        }
    }

    /// T105: EOF inside quote throws invalidQuoting.
    func testT105_eofInsideQuote() throws {
        let input = "a\n\""
        XCTAssertThrowsError(try parser.parse(input)) { error in
            guard case Csv.Error.invalidQuoting = error else {
                XCTFail("Expected invalidQuoting, got \(error)")
                return
            }
        }
    }

    // MARK: - Boundary cases

    /// T201: Single column, single row.
    func testT201_singleColumnSingleRow() throws {
        let input = "header\nvalue"
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.count, 1)
        XCTAssertEqual(result.columns[0].name, "header")
        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0].values, ["value"])
    }

    /// T202: Empty fields only.
    func testT202_emptyFieldsOnly() throws {
        let input = "a,b\n,"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values, ["", ""])
    }

    /// T206: Unicode/Japanese characters.
    func testT206_unicodeJapanese() throws {
        let input = "名前,値\n東京,100"
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.map(\.name), ["名前", "値"])
        XCTAssertEqual(result.rows[0].values, ["東京", "100"])
    }

    /// T207: Emoji characters.
    func testT207_emoji() throws {
        let input = "a,b\n🎉,🚀"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values, ["🎉", "🚀"])
    }
}
