import CoreGraphics
import Foundation

/// An RFC 4180 compliant CSV parser using a state machine approach.
///
/// The parser iterates through the input using `String.UnicodeScalarView` for performance
/// and handles quoted fields, escaped quotes, and mixed newline styles.
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

    public init() {}

    public func parse(_ string: String, options: Options = .init()) throws -> CsvParseResult {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw Csv.Error.emptyData
        }

        let separatorScalar = options.separator.unicodeScalars.first!
        let scalars = string.unicodeScalars
        var index = scalars.startIndex

        // State machine states
        enum State {
            case fieldStart
            case unquotedField
            case quotedField
            case quoteInQuoted
            case rowEnd
        }

        var state: State = .fieldStart
        var currentField = ""
        var currentRow: [String] = []
        var allRows: [[String]] = []

        // Tracking line/column for error reporting (1-based)
        var line = 1
        var column = 1

        // Helpers
        func peekScalar() -> Unicode.Scalar? {
            guard index < scalars.endIndex else { return nil }
            return scalars[index]
        }

        func advanceIndex() {
            index = scalars.index(after: index)
            column += 1
        }

        func commitField() {
            currentRow.append(currentField)
            currentField = ""
        }

        func commitRow() {
            allRows.append(currentRow)
            currentRow = []
            line += 1
            column = 1
        }

        mainLoop: while true {
            switch state {
            case .fieldStart:
                guard let scalar = peekScalar() else {
                    // EOF at field start — if we have accumulated fields in the current row,
                    // commit an empty field and the row. Otherwise we are done.
                    if !currentRow.isEmpty {
                        commitField()
                        commitRow()
                    }
                    break mainLoop
                }

                if scalar == "\"" {
                    advanceIndex()
                    state = .quotedField
                } else if scalar == separatorScalar {
                    commitField()
                    advanceIndex()
                    state = .fieldStart
                } else if scalar == "\r" {
                    commitField()
                    advanceIndex()
                    // Check for \r\n
                    if let next = peekScalar(), next == "\n" {
                        advanceIndex()
                    }
                    commitRow()
                    state = .fieldStart
                } else if scalar == "\n" {
                    commitField()
                    advanceIndex()
                    commitRow()
                    state = .fieldStart
                } else {
                    currentField.unicodeScalars.append(scalar)
                    advanceIndex()
                    state = .unquotedField
                }

            case .unquotedField:
                guard let scalar = peekScalar() else {
                    commitField()
                    commitRow()
                    break mainLoop
                }

                if scalar == separatorScalar {
                    commitField()
                    advanceIndex()
                    state = .fieldStart
                } else if scalar == "\r" {
                    commitField()
                    advanceIndex()
                    if let next = peekScalar(), next == "\n" {
                        advanceIndex()
                    }
                    commitRow()
                    state = .fieldStart
                } else if scalar == "\n" {
                    commitField()
                    advanceIndex()
                    commitRow()
                    state = .fieldStart
                } else {
                    currentField.unicodeScalars.append(scalar)
                    advanceIndex()
                }

            case .quotedField:
                guard let scalar = peekScalar() else {
                    // Non-RFC 4180: EOF inside quoted field.
                    // Treat the opening quote as part of content and commit what we have.
                    commitField()
                    commitRow()
                    break mainLoop
                }

                if scalar == "\"" {
                    advanceIndex()
                    state = .quoteInQuoted
                } else {
                    // Track newlines inside quoted fields for accurate error reporting
                    if scalar == "\r" {
                        currentField.unicodeScalars.append(scalar)
                        advanceIndex()
                        if let next = peekScalar(), next == "\n" {
                            currentField.unicodeScalars.append(next)
                            advanceIndex()
                        }
                        line += 1
                        column = 1
                    } else if scalar == "\n" {
                        currentField.unicodeScalars.append(scalar)
                        advanceIndex()
                        line += 1
                        column = 1
                    } else {
                        currentField.unicodeScalars.append(scalar)
                        advanceIndex()
                    }
                }

            case .quoteInQuoted:
                let scalar = peekScalar()

                if let scalar, scalar == "\"" {
                    // Escaped quote "" -> "
                    currentField.unicodeScalars.append("\"")
                    advanceIndex()
                    state = .quotedField
                } else if let scalar, scalar == separatorScalar {
                    commitField()
                    advanceIndex()
                    state = .fieldStart
                } else if let scalar, scalar == "\r" {
                    commitField()
                    advanceIndex()
                    if let next = peekScalar(), next == "\n" {
                        advanceIndex()
                    }
                    commitRow()
                    state = .fieldStart
                } else if let scalar, scalar == "\n" {
                    commitField()
                    advanceIndex()
                    commitRow()
                    state = .fieldStart
                } else if scalar == nil {
                    // EOF after closing quote
                    commitField()
                    commitRow()
                    break mainLoop
                } else {
                    // Non-RFC 4180: unexpected character after closing quote.
                    // Treat the closing quote as part of the field content and
                    // continue as an unquoted field for resilience.
                    currentField.unicodeScalars.append("\"")
                    currentField.unicodeScalars.append(scalar!)
                    advanceIndex()
                    state = .unquotedField
                }

            case .rowEnd:
                state = .fieldStart
            }
        }

        guard !allRows.isEmpty else {
            throw Csv.Error.emptyData
        }

        // First row is the header
        let headerFields = allRows[0]
        let columnCount = headerFields.count
        let styles = Csv.Column.Style.random(count: columnCount)
        let columns: [Csv.Column] = headerFields.enumerated().map { i, name in
            Csv.Column(name: name, style: styles[i])
        }

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

    /// Parses a CSV string and yields rows in chunks via an `AsyncThrowingStream`.
    public func parseAsStream(
        _ string: String,
        options: StreamOptions = .init()
    ) -> AsyncThrowingStream<CsvParseResult.Chunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        throw Csv.Error.emptyData
                    }

                    let separatorScalar = options.separator.unicodeScalars.first!
                    let scalars = string.unicodeScalars
                    var index = scalars.startIndex

                    enum State {
                        case fieldStart, unquotedField, quotedField, quoteInQuoted, rowEnd
                    }

                    var state: State = .fieldStart
                    var currentField = ""
                    var currentRow: [String] = []
                    var allRawRows: [[String]] = []

                    var line = 1
                    var column = 1

                    func peekScalar() -> Unicode.Scalar? {
                        guard index < scalars.endIndex else { return nil }
                        return scalars[index]
                    }
                    func advanceIndex() {
                        index = scalars.index(after: index)
                        column += 1
                    }
                    func commitField() {
                        currentRow.append(currentField)
                        currentField = ""
                    }
                    func commitRow() {
                        allRawRows.append(currentRow)
                        currentRow = []
                        line += 1
                        column = 1
                    }

                    // Parse all raw rows using the same state machine as parse()
                    mainLoop: while true {
                        switch state {
                        case .fieldStart:
                            guard let scalar = peekScalar() else {
                                if !currentRow.isEmpty {
                                    commitField()
                                    commitRow()
                                }
                                break mainLoop
                            }
                            if scalar == "\"" {
                                advanceIndex()
                                state = .quotedField
                            } else if scalar == separatorScalar {
                                commitField()
                                advanceIndex()
                                state = .fieldStart
                            } else if scalar == "\r" {
                                commitField()
                                advanceIndex()
                                if let next = peekScalar(), next == "\n" { advanceIndex() }
                                commitRow()
                                state = .fieldStart
                            } else if scalar == "\n" {
                                commitField()
                                advanceIndex()
                                commitRow()
                                state = .fieldStart
                            } else {
                                currentField.unicodeScalars.append(scalar)
                                advanceIndex()
                                state = .unquotedField
                            }
                        case .unquotedField:
                            guard let scalar = peekScalar() else {
                                commitField()
                                commitRow()
                                break mainLoop
                            }
                            if scalar == separatorScalar {
                                commitField()
                                advanceIndex()
                                state = .fieldStart
                            } else if scalar == "\r" {
                                commitField()
                                advanceIndex()
                                if let next = peekScalar(), next == "\n" { advanceIndex() }
                                commitRow()
                                state = .fieldStart
                            } else if scalar == "\n" {
                                commitField()
                                advanceIndex()
                                commitRow()
                                state = .fieldStart
                            } else {
                                currentField.unicodeScalars.append(scalar)
                                advanceIndex()
                            }
                        case .quotedField:
                            guard let scalar = peekScalar() else {
                                commitField()
                                commitRow()
                                break mainLoop
                            }
                            if scalar == "\"" {
                                advanceIndex()
                                state = .quoteInQuoted
                            } else {
                                if scalar == "\r" {
                                    currentField.unicodeScalars.append(scalar)
                                    advanceIndex()
                                    if let next = peekScalar(), next == "\n" {
                                        currentField.unicodeScalars.append(next)
                                        advanceIndex()
                                    }
                                    line += 1; column = 1
                                } else if scalar == "\n" {
                                    currentField.unicodeScalars.append(scalar)
                                    advanceIndex()
                                    line += 1; column = 1
                                } else {
                                    currentField.unicodeScalars.append(scalar)
                                    advanceIndex()
                                }
                            }
                        case .quoteInQuoted:
                            let scalar = peekScalar()
                            if let scalar, scalar == "\"" {
                                currentField.unicodeScalars.append("\"")
                                advanceIndex()
                                state = .quotedField
                            } else if let scalar, scalar == separatorScalar {
                                commitField()
                                advanceIndex()
                                state = .fieldStart
                            } else if let scalar, scalar == "\r" {
                                commitField()
                                advanceIndex()
                                if let next = peekScalar(), next == "\n" { advanceIndex() }
                                commitRow()
                                state = .fieldStart
                            } else if let scalar, scalar == "\n" {
                                commitField()
                                advanceIndex()
                                commitRow()
                                state = .fieldStart
                            } else if scalar == nil {
                                commitField()
                                commitRow()
                                break mainLoop
                            } else {
                                currentField.unicodeScalars.append("\"")
                                currentField.unicodeScalars.append(scalar!)
                                advanceIndex()
                                state = .unquotedField
                            }
                        case .rowEnd:
                            state = .fieldStart
                        }
                    }

                    guard !allRawRows.isEmpty else {
                        throw Csv.Error.emptyData
                    }

                    // Build columns from header
                    let headerFields = allRawRows[0]
                    let columnCount = headerFields.count
                    let styles = Csv.Column.Style.random(count: columnCount)
                    let columns: [Csv.Column] = headerFields.enumerated().map { i, name in
                        Csv.Column(name: name, style: styles[i])
                    }

                    // Yield data rows in chunks
                    var chunkIndex = 0
                    var bufferedRows: [Csv.Row] = []
                    var bufferedWarnings: [CsvParseResult.Warning] = []
                    let dataRowCount = allRawRows.count - 1

                    for rawIndex in 1..<allRawRows.count {
                        let (row, rowWarnings) = Self.validateAndBuildRow(
                            rawFields: allRawRows[rawIndex],
                            columnCount: columnCount,
                            rowIndex: rawIndex,
                            maxFieldLength: options.maxFieldLength
                        )
                        bufferedRows.append(row)
                        bufferedWarnings.append(contentsOf: rowWarnings)

                        if bufferedRows.count >= options.chunkSize {
                            let isLast = rawIndex == dataRowCount
                            continuation.yield(CsvParseResult.Chunk(
                                index: chunkIndex,
                                columns: columns,
                                rows: bufferedRows,
                                warnings: bufferedWarnings,
                                isFinal: isLast
                            ))
                            bufferedRows = []
                            bufferedWarnings = []
                            chunkIndex += 1
                        }
                    }

                    // Yield remaining rows as final chunk
                    if !bufferedRows.isEmpty || chunkIndex == 0 {
                        continuation.yield(CsvParseResult.Chunk(
                            index: chunkIndex,
                            columns: columns,
                            rows: bufferedRows,
                            warnings: bufferedWarnings,
                            isFinal: true
                        ))
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Helpers

    static func validateAndBuildRow(
        rawFields: [String],
        columnCount: Int,
        rowIndex: Int,
        maxFieldLength: Int?
    ) -> (row: Csv.Row, warnings: [CsvParseResult.Warning]) {
        var fields = rawFields
        var warnings: [CsvParseResult.Warning] = []
        let actualCount = fields.count

        if actualCount < columnCount {
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
