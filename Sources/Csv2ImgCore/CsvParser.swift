import CoreGraphics
import Foundation

/// An RFC 4180 compliant CSV parser using a state machine approach.
///
/// The parser iterates through the input using `String.UnicodeScalarView` for performance
/// and handles quoted fields, escaped quotes, and mixed newline styles.
/// Lines with no characters are kept as rows of empty fields when they sit between rows,
/// and skipped before the header and after the last row.
public struct CsvParser: Sendable {

    public struct Options: Sendable {
        public var separator: Character
        public var maxFieldLength: Int?

        public init(
            separator: Character = ",",
            maxFieldLength: Int? = nil
        ) {
            self.separator = separator
            self.maxFieldLength = maxFieldLength
        }
    }

    public struct StreamOptions: Sendable {
        public var separator: Character
        public var maxFieldLength: Int?
        public var chunkSize: Int

        public init(
            separator: Character = ",",
            maxFieldLength: Int? = nil,
            chunkSize: Int = 300
        ) {
            self.separator = separator
            self.maxFieldLength = maxFieldLength
            self.chunkSize = chunkSize
        }
    }

    public init() {}

    // MARK: - Batch API

    public func parse(_ string: String, options: Options = .init()) throws -> CsvParseResult {
        var machine = try StateMachine(string: string, separator: options.separator)

        var allRows: [[String]] = []
        while let row = machine.nextRow() {
            allRows.append(row)
        }

        guard !allRows.isEmpty else {
            throw Csv.Error.emptyData
        }

        let columns = Self.makeColumns(from: allRows[0])
        let columnCount = columns.count

        var warnings: [CsvParseResult.Warning] = []
        var rows: [Csv.Row] = []

        for rowIndex in 1..<allRows.count {
            let (row, rowWarnings) = Self.validateAndBuildRow(
                rawFields: allRows[rowIndex],
                columnCount: columnCount,
                rowIndex: rowIndex,
                maxFieldLength: options.maxFieldLength
            )
            rows.append(row)
            warnings.append(contentsOf: rowWarnings)
        }

        return CsvParseResult(
            columns: columns,
            rows: rows,
            warnings: warnings,
            detectedSeparator: options.separator
        )
    }

    // MARK: - Streaming API

    /// Parses a CSV string and yields rows in chunks via an `AsyncThrowingStream`.
    ///
    /// Rows are parsed incrementally, so the first chunk is delivered as soon as
    /// `chunkSize` rows are read, and parsing stops when the stream is terminated.
    public func parseAsStream(
        _ string: String,
        options: StreamOptions = .init()
    ) -> AsyncThrowingStream<CsvParseResult.Chunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try Self.yieldChunks(of: string, options: options, to: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func yieldChunks(
        of string: String,
        options: StreamOptions,
        to continuation: AsyncThrowingStream<CsvParseResult.Chunk, Error>.Continuation
    ) throws {
        var machine = try StateMachine(string: string, separator: options.separator)
        guard let headerFields = machine.nextRow() else {
            throw Csv.Error.emptyData
        }
        let columns = makeColumns(from: headerFields)

        var chunkIndex = 0
        var rowIndex = 0
        var bufferedRows: [Csv.Row] = []
        var bufferedWarnings: [CsvParseResult.Warning] = []
        var nextFields = machine.nextRow()

        while let rawFields = nextFields {
            try Task.checkCancellation()
            rowIndex += 1
            let (row, rowWarnings) = validateAndBuildRow(
                rawFields: rawFields,
                columnCount: columns.count,
                rowIndex: rowIndex,
                maxFieldLength: options.maxFieldLength
            )
            bufferedRows.append(row)
            bufferedWarnings.append(contentsOf: rowWarnings)

            // Reading one row ahead is the only way to know whether this chunk is the last one.
            nextFields = machine.nextRow()
            let isFinal = nextFields == nil
            guard isFinal || bufferedRows.count >= options.chunkSize else { continue }

            continuation.yield(CsvParseResult.Chunk(
                index: chunkIndex,
                columns: columns,
                rows: bufferedRows,
                warnings: bufferedWarnings,
                isFinal: isFinal
            ))
            bufferedRows = []
            bufferedWarnings = []
            chunkIndex += 1
        }

        if chunkIndex == 0 {
            continuation.yield(CsvParseResult.Chunk(
                index: 0,
                columns: columns,
                rows: [],
                warnings: [],
                isFinal: true
            ))
        }
    }

    private static func makeColumns(from headerFields: [String]) -> [Csv.Column] {
        let styles = Csv.Column.Style.random(count: headerFields.count)
        return headerFields.enumerated().map { i, name in
            Csv.Column(name: name, style: styles[i])
        }
    }

    // MARK: - Row Validation

    static func validateAndBuildRow(
        rawFields: [String],
        columnCount: Int,
        rowIndex: Int,
        maxFieldLength: Int?
    ) -> (row: Csv.Row, warnings: [CsvParseResult.Warning]) {
        var fields = rawFields
        var warnings: [CsvParseResult.Warning] = []
        let actualCount = fields.count

        if rawFields == StateMachine.blankLine {
            fields = Array(repeating: "", count: columnCount)
        } else if actualCount < columnCount {
            warnings.append(CsvParseResult.Warning(
                kind: .columnCountMismatch(expected: columnCount, actual: actualCount),
                row: rowIndex
            ))
            while fields.count < columnCount {
                fields.append("")
            }
        } else if actualCount > columnCount {
            warnings.append(CsvParseResult.Warning(
                kind: .columnCountMismatch(expected: columnCount, actual: actualCount),
                row: rowIndex
            ))
            fields = Array(fields.prefix(columnCount))
        }

        if let maxLen = maxFieldLength {
            for fieldIndex in 0..<fields.count {
                if fields[fieldIndex].count > maxLen {
                    let originalLength = fields[fieldIndex].count
                    warnings.append(CsvParseResult.Warning(
                        kind: .fieldTruncated(originalLength: originalLength, maxLength: maxLen),
                        row: rowIndex
                    ))
                    let truncateAt = max(maxLen - 3, 0)
                    fields[fieldIndex] = String(fields[fieldIndex].prefix(truncateAt)) + "..."
                }
            }
        }

        return (Csv.Row(index: rowIndex, values: fields), warnings)
    }
}

// MARK: - State Machine

extension CsvParser {

    /// Encapsulates the CSV parsing state machine.
    /// Call `nextRow()` repeatedly to get each raw row as `[String]`, or `nil` at EOF.
    struct StateMachine {

        /// The row returned for a line with no characters. A line holding only `""` is `[""]` instead.
        static let blankLine: [String] = []

        enum State {
            case fieldStart
            case unquotedField
            case quotedField
            case quoteInQuoted
        }

        private let scalars: String.UnicodeScalarView
        private let separatorScalar: Unicode.Scalar
        private var index: String.UnicodeScalarView.Index
        private var state: State = .fieldStart
        private var currentField = ""
        private var currentRow: [String] = []
        private var finished = false
        private var heldRow: [String]?
        private var pendingBlankLines = 0
        private var hasReturnedRow = false

        // Position tracking (1-based)
        private(set) var line = 1
        private(set) var column = 1

        init(string: String, separator: Character) throws {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                throw Csv.Error.emptyData
            }
            self.scalars = string.unicodeScalars
            let byteOrderMark: Unicode.Scalar = "\u{FEFF}"
            self.index = scalars.first == byteOrderMark ? scalars.index(after: scalars.startIndex) : scalars.startIndex
            self.separatorScalar = separator.unicodeScalars.first!
        }

        /// Returns the next parsed row as an array of field strings, or `nil` at EOF.
        ///
        /// Blank lines are held back until the next row arrives, so the ones after the last row are never returned.
        mutating func nextRow() -> [String]? {
            while heldRow == nil && !finished {
                heldRow = step()
            }
            guard let row = heldRow else { return nil }
            if pendingBlankLines > 0 {
                pendingBlankLines -= 1
                return Self.blankLine
            }
            heldRow = nil
            hasReturnedRow = true
            return row
        }

        // MARK: - Transitions

        private mutating func step() -> [String]? {
            guard let scalar = peek() else { return handleEndOfInput() }

            switch state {
            case .fieldStart:
                return handleFieldStart(scalar)
            case .unquotedField:
                return handleUnquotedField(scalar)
            case .quotedField:
                handleQuotedField(scalar)
                return nil
            case .quoteInQuoted:
                return handleQuoteInQuoted(scalar)
            }
        }

        private mutating func handleEndOfInput() -> [String]? {
            finished = true
            if state == .fieldStart && currentRow.isEmpty { return nil }
            commitField()
            return commitAndReturnRow()
        }

        private mutating func handleFieldStart(_ scalar: Unicode.Scalar) -> [String]? {
            if currentRow.isEmpty && isLineBreak(scalar) {
                skipBlankLine(at: scalar)
                return nil
            }
            if scalar == "\"" {
                advance()
                state = .quotedField
                return nil
            }
            state = .unquotedField
            return handleUnquotedField(scalar)
        }

        private mutating func handleUnquotedField(_ scalar: Unicode.Scalar) -> [String]? {
            if isFieldBoundary(scalar) { return closeField(at: scalar) }
            currentField.unicodeScalars.append(scalar)
            advance()
            return nil
        }

        private mutating func handleQuotedField(_ scalar: Unicode.Scalar) {
            if scalar == "\"" {
                advance()
                state = .quoteInQuoted
                return
            }
            currentField.unicodeScalars.append(scalar)
            advance()
            guard isLineBreak(scalar) else { return }
            if scalar == "\r", let next = peek(), next == "\n" {
                currentField.unicodeScalars.append(next)
                advance()
            }
            line += 1
            column = 1
        }

        private mutating func handleQuoteInQuoted(_ scalar: Unicode.Scalar) -> [String]? {
            if scalar == "\"" {
                currentField.unicodeScalars.append("\"")
                advance()
                state = .quotedField
                return nil
            }
            if isFieldBoundary(scalar) { return closeField(at: scalar) }
            // Non-RFC 4180: keep the stray quote instead of rejecting the whole file.
            currentField.unicodeScalars.append("\"")
            currentField.unicodeScalars.append(scalar)
            advance()
            state = .unquotedField
            return nil
        }

        private mutating func closeField(at scalar: Unicode.Scalar) -> [String]? {
            commitField()
            advance()
            if scalar == separatorScalar {
                state = .fieldStart
                return nil
            }
            if scalar == "\r", let next = peek(), next == "\n" { advance() }
            return commitAndReturnRow()
        }

        private mutating func skipBlankLine(at scalar: Unicode.Scalar) {
            advance()
            if scalar == "\r", let next = peek(), next == "\n" { advance() }
            line += 1
            column = 1
            if hasReturnedRow { pendingBlankLines += 1 }
        }

        private func isFieldBoundary(_ scalar: Unicode.Scalar) -> Bool {
            scalar == separatorScalar || isLineBreak(scalar)
        }

        private func isLineBreak(_ scalar: Unicode.Scalar) -> Bool {
            scalar == "\r" || scalar == "\n"
        }

        // MARK: - Private

        private func peek() -> Unicode.Scalar? {
            guard index < scalars.endIndex else { return nil }
            return scalars[index]
        }

        private mutating func advance() {
            index = scalars.index(after: index)
            column += 1
        }

        private mutating func commitField() {
            currentRow.append(currentField)
            currentField = ""
        }

        private mutating func commitAndReturnRow() -> [String] {
            let row = currentRow
            currentRow = []
            line += 1
            column = 1
            state = .fieldStart
            return row
        }
    }
}
