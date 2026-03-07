import CoreGraphics
import Foundation

/// An RFC 4180 compliant CSV parser using a state machine approach.
///
/// The parser iterates through the input using `String.UnicodeScalarView` for performance
/// and handles quoted fields, escaped quotes, and mixed newline styles.
public struct CsvParser: Sendable {

    public struct Options: Sendable {
        public var separator: Character
        public var encoding: String.Encoding
        public var maxFieldLength: Int?

        public init(
            separator: Character = ",",
            encoding: String.Encoding = .utf8,
            maxFieldLength: Int? = nil
        ) {
            self.separator = separator
            self.encoding = encoding
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
                    throw Csv.Error.invalidQuoting(line: line, column: column)
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
                    throw Csv.Error.invalidQuoting(line: line, column: column)
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
            var fields = allRows[rowIndex]
            let actualCount = fields.count

            if actualCount < columnCount {
                // Pad with empty strings
                warnings.append(CsvParseResult.Warning(
                    kind: .columnCountMismatch(expected: columnCount, actual: actualCount),
                    row: rowIndex
                ))
                while fields.count < columnCount {
                    fields.append("")
                }
            } else if actualCount > columnCount {
                // Truncate
                warnings.append(CsvParseResult.Warning(
                    kind: .columnCountMismatch(expected: columnCount, actual: actualCount),
                    row: rowIndex
                ))
                fields = Array(fields.prefix(columnCount))
            }

            // Apply maxFieldLength truncation
            if let maxLen = options.maxFieldLength {
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

            rows.append(Csv.Row(index: rowIndex, values: fields))
        }

        return CsvParseResult(
            columns: columns,
            rows: rows,
            warnings: warnings,
            detectedSeparator: options.separator
        )
    }
}
