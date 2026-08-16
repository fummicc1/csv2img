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

    /// T103: Unclosed quote falls back gracefully instead of throwing.
    func testT103_unclosedQuote() throws {
        let input = "a\n\"unclosed"
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.count, 1)
        XCTAssertEqual(result.rows.count, 1)
        // The unclosed quoted field is committed as-is
        XCTAssertEqual(result.rows[0].values, ["unclosed"])
    }

    /// T104: Invalid char after closing quote falls back to unquoted field.
    func testT104_invalidCharAfterClosingQuote() throws {
        let input = "a\n\"value\"x"
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.count, 1)
        XCTAssertEqual(result.rows.count, 1)
        // The closing quote and trailing char are treated as content
        XCTAssertEqual(result.rows[0].values, ["value\"x"])
    }

    /// T105: EOF inside quote falls back gracefully.
    func testT105_eofInsideQuote() throws {
        let input = "a\n\""
        let result = try parser.parse(input)
        XCTAssertEqual(result.columns.count, 1)
        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0].values, [""])
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

    // MARK: - Non-RFC 4180 resilience

    /// T301: Bare quote in unquoted field is treated as regular character.
    func testT301_bareQuoteInUnquotedField() throws {
        let input = "a,b\nHe said \"hello\",world"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values, ["He said \"hello\"", "world"])
    }

    /// T302: Quote after closing quote falls back to unquoted mode.
    func testT302_quoteAfterClosingQuoteFallback() throws {
        let input = "a,b\n\"val\"ue,other"
        let result = try parser.parse(input)
        XCTAssertEqual(result.rows[0].values, ["val\"ue", "other"])
    }

    /// T303: Unclosed quote at EOF commits field content (padded to column count).
    func testT303_unclosedQuoteAtEofCommitsContent() throws {
        let input = "a,b\n\"unclosed,data"
        let result = try parser.parse(input)
        // The unclosed quoted field captures everything until EOF as one field.
        // Since header has 2 columns, the row is padded with an empty string.
        XCTAssertEqual(result.rows[0].values, ["unclosed,data", ""])
    }

    /// T304: loadFromString with non-RFC 4180 quotes succeeds.
    func testT304_loadFromStringWithBareQuotes() async throws {
        let input = "name,desc\nAlice,She said \"hi\""
        let csv = try Csv.loadFromString(input)
        let columns = await csv.columns
        let rows = await csv.rows
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].values, ["Alice", "She said \"hi\""])
    }

    // MARK: - Streaming API tests

    /// S001: Small CSV fits in one chunk.
    func testS001_singleChunk() async throws {
        let input = "a,b,c\n1,2,3\n4,5,6"
        var chunks: [CsvParseResult.Chunk] = []
        for try await chunk in parser.parseAsStream(input) {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].index, 0)
        XCTAssertTrue(chunks[0].isFinal)
        XCTAssertEqual(chunks[0].columns.map(\.name), ["a", "b", "c"])
        XCTAssertEqual(chunks[0].rows.count, 2)
    }

    /// S002: Multiple chunks with chunkSize=3.
    func testS002_multipleChunks() async throws {
        var lines = ["h1,h2"]
        for i in 0..<10 { lines.append("\(i),val\(i)") }
        let input = lines.joined(separator: "\n")

        var chunks: [CsvParseResult.Chunk] = []
        let opts = CsvParser.StreamOptions(chunkSize: 3)
        for try await chunk in parser.parseAsStream(input, options: opts) {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks.count, 4) // 3+3+3+1
        XCTAssertEqual(chunks[0].rows.count, 3)
        XCTAssertEqual(chunks[1].rows.count, 3)
        XCTAssertEqual(chunks[2].rows.count, 3)
        XCTAssertEqual(chunks[3].rows.count, 1)
        XCTAssertFalse(chunks[0].isFinal)
        XCTAssertFalse(chunks[1].isFinal)
        XCTAssertFalse(chunks[2].isFinal)
        XCTAssertTrue(chunks[3].isFinal)
    }

    /// S003: All chunks have the same columns.
    func testS003_columnsInEveryChunk() async throws {
        var lines = ["name,value"]
        for i in 0..<7 { lines.append("r\(i),\(i)") }
        let input = lines.joined(separator: "\n")

        let opts = CsvParser.StreamOptions(chunkSize: 2)
        var columnSets: [[String]] = []
        for try await chunk in parser.parseAsStream(input, options: opts) {
            columnSets.append(chunk.columns.map(\.name))
        }
        for set in columnSets {
            XCTAssertEqual(set, ["name", "value"])
        }
    }

    /// S004: Row indices are global across chunks.
    func testS004_globalRowIndices() async throws {
        var lines = ["a"]
        for i in 0..<5 { lines.append("r\(i)") }
        let input = lines.joined(separator: "\n")

        let opts = CsvParser.StreamOptions(chunkSize: 2)
        var allIndices: [Int] = []
        for try await chunk in parser.parseAsStream(input, options: opts) {
            allIndices.append(contentsOf: chunk.rows.map(\.index))
        }
        XCTAssertEqual(allIndices, [1, 2, 3, 4, 5])
    }

    /// S005: Empty string throws emptyData.
    func testS005_emptyStringThrows() async {
        var thrownError: Error?
        do {
            for try await _ in parser.parseAsStream("") {
                XCTFail("Should not yield any chunks")
            }
        } catch {
            thrownError = error
        }
        XCTAssertTrue(thrownError is Csv.Error)
    }

    /// S006: Header-only CSV yields one chunk with 0 rows.
    func testS006_headerOnlyYieldsEmptyChunk() async throws {
        var chunks: [CsvParseResult.Chunk] = []
        for try await chunk in parser.parseAsStream("a,b,c") {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks.count, 1)
        XCTAssertTrue(chunks[0].isFinal)
        XCTAssertEqual(chunks[0].rows.count, 0)
        XCTAssertEqual(chunks[0].columns.count, 3)
    }

    /// S007: Warnings appear in the correct chunk.
    func testS007_warningsInCorrectChunk() async throws {
        // Row 4 has too few fields (chunkSize=3, so it's in chunk 1)
        let input = "a,b\n1,2\n3,4\n5,6\n7\n8,9"
        let opts = CsvParser.StreamOptions(chunkSize: 3)
        var chunks: [CsvParseResult.Chunk] = []
        for try await chunk in parser.parseAsStream(input, options: opts) {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks.count, 2)
        XCTAssertTrue(chunks[0].warnings.isEmpty)
        XCTAssertEqual(chunks[1].warnings.count, 1)
    }

    /// S008: Quoted fields with newlines work in streaming.
    func testS008_quotedFieldsInStream() async throws {
        let input = "a,b\n\"line1\nline2\",val"
        var chunks: [CsvParseResult.Chunk] = []
        for try await chunk in parser.parseAsStream(input) {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks[0].rows[0].values, ["line1\nline2", "val"])
    }

    /// S009: maxFieldLength truncation works in streaming.
    func testS009_maxFieldLengthInStream() async throws {
        let input = "a\n12345678901234567890"
        let opts = CsvParser.StreamOptions(maxFieldLength: 10)
        var chunks: [CsvParseResult.Chunk] = []
        for try await chunk in parser.parseAsStream(input, options: opts) {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks[0].rows[0].values, ["1234567..."])
    }

    /// S010: Streaming result equals batch parse result.
    func testS010_equivalenceWithParse() async throws {
        let input = "name,value,unit\nAlpha,1.00,H\nBeta,2.00,page\nGamma,3.00,item\nDelta,4.00,step"
        let batchResult = try parser.parse(input)

        let opts = CsvParser.StreamOptions(chunkSize: 2)
        var streamColumns: [Csv.Column] = []
        var streamRows: [Csv.Row] = []
        var streamWarnings: [CsvParseResult.Warning] = []
        for try await chunk in parser.parseAsStream(input, options: opts) {
            streamColumns = chunk.columns
            streamRows.append(contentsOf: chunk.rows)
            streamWarnings.append(contentsOf: chunk.warnings)
        }

        XCTAssertEqual(streamColumns.map(\.name), batchResult.columns.map(\.name))
        XCTAssertEqual(streamRows.map(\.values), batchResult.rows.map(\.values))
        XCTAssertEqual(streamRows.map(\.index), batchResult.rows.map(\.index))
        XCTAssertEqual(streamWarnings, batchResult.warnings)
    }
}
