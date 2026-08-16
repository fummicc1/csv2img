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

    /// Parses a CSV string and yields rows in chunks via an `AsyncThrowingStream`.
    public func parseAsStream(
        _ string: String,
        options: StreamOptions = .init()
    ) -> AsyncThrowingStream<CsvParseResult.Chunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var machine = try StateMachine(string: string, separator: options.separator)

                    var allRawRows: [[String]] = []
                    while let row = machine.nextRow() {
                        allRawRows.append(row)
                    }

                    guard !allRawRows.isEmpty else {
                        throw Csv.Error.emptyData
                    }

                    let headerFields = allRawRows[0]
                    let columnCount = headerFields.count
                    let styles = Csv.Column.Style.random(count: columnCount)
                    let columns: [Csv.Column] = headerFields.enumerated().map { i, name in
                        Csv.Column(name: name, style: styles[i])
                    }

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

// MARK: - State Machine

extension CsvParser {

    /// Encapsulates the CSV parsing state machine.
    /// Call `nextRow()` repeatedly to get each raw row as `[String]`, or `nil` at EOF.
    struct StateMachine {

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

        // Position tracking (1-based)
        private(set) var line = 1
        private(set) var column = 1

        init(string: String, separator: Character) throws {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                throw Csv.Error.emptyData
            }
            self.scalars = string.unicodeScalars
            self.index = scalars.startIndex
            self.separatorScalar = separator.unicodeScalars.first!
        }

        /// Returns the next parsed row as an array of field strings, or `nil` at EOF.
        mutating func nextRow() -> [String]? {
            guard !finished else { return nil }

            while true {
                switch state {
                case .fieldStart:
                    guard let scalar = peek() else {
                        if !currentRow.isEmpty {
                            commitField()
                            return commitAndReturnRow()
                        }
                        finished = true
                        return nil
                    }

                    if scalar == "\"" {
                        advance()
                        state = .quotedField
                    } else if scalar == separatorScalar {
                        commitField()
                        advance()
                        state = .fieldStart
                    } else if scalar == "\r" {
                        commitField()
                        advance()
                        if let next = peek(), next == "\n" { advance() }
                        return commitAndReturnRow()
                    } else if scalar == "\n" {
                        commitField()
                        advance()
                        return commitAndReturnRow()
                    } else {
                        currentField.unicodeScalars.append(scalar)
                        advance()
                        state = .unquotedField
                    }

                case .unquotedField:
                    guard let scalar = peek() else {
                        commitField()
                        finished = true
                        return commitAndReturnRow()
                    }

                    if scalar == separatorScalar {
                        commitField()
                        advance()
                        state = .fieldStart
                    } else if scalar == "\r" {
                        commitField()
                        advance()
                        if let next = peek(), next == "\n" { advance() }
                        return commitAndReturnRow()
                    } else if scalar == "\n" {
                        commitField()
                        advance()
                        return commitAndReturnRow()
                    } else {
                        currentField.unicodeScalars.append(scalar)
                        advance()
                    }

                case .quotedField:
                    guard let scalar = peek() else {
                        // Non-RFC 4180: EOF inside quoted field.
                        commitField()
                        finished = true
                        return commitAndReturnRow()
                    }

                    if scalar == "\"" {
                        advance()
                        state = .quoteInQuoted
                    } else if scalar == "\r" {
                        currentField.unicodeScalars.append(scalar)
                        advance()
                        if let next = peek(), next == "\n" {
                            currentField.unicodeScalars.append(next)
                            advance()
                        }
                        line += 1; column = 1
                    } else if scalar == "\n" {
                        currentField.unicodeScalars.append(scalar)
                        advance()
                        line += 1; column = 1
                    } else {
                        currentField.unicodeScalars.append(scalar)
                        advance()
                    }

                case .quoteInQuoted:
                    guard let scalar = peek() else {
                        // EOF after closing quote
                        commitField()
                        finished = true
                        return commitAndReturnRow()
                    }

                    if scalar == "\"" {
                        // Escaped quote "" -> "
                        currentField.unicodeScalars.append("\"")
                        advance()
                        state = .quotedField
                    } else if scalar == separatorScalar {
                        commitField()
                        advance()
                        state = .fieldStart
                    } else if scalar == "\r" {
                        commitField()
                        advance()
                        if let next = peek(), next == "\n" { advance() }
                        return commitAndReturnRow()
                    } else if scalar == "\n" {
                        commitField()
                        advance()
                        return commitAndReturnRow()
                    } else {
                        // Non-RFC 4180: unexpected character after closing quote.
                        currentField.unicodeScalars.append("\"")
                        currentField.unicodeScalars.append(scalar)
                        advance()
                        state = .unquotedField
                    }
                }
            }
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
