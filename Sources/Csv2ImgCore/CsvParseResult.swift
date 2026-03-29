import Foundation

/// Result of parsing a CSV string, containing columns, rows, warnings, and the detected separator.
public struct CsvParseResult: Sendable {

    /// A warning generated during CSV parsing that does not prevent parsing from completing.
    public struct Warning: Sendable, Equatable {
        public enum Kind: Sendable, Equatable {
            /// The number of fields in a row did not match the header column count.
            case columnCountMismatch(expected: Int, actual: Int)
            /// A field was truncated because it exceeded the maximum field length.
            case fieldTruncated(originalLength: Int, maxLength: Int)
        }
        public let kind: Kind
        public let row: Int
    }

    public let columns: [Csv.Column]
    public let rows: [Csv.Row]
    public let warnings: [Warning]
    public let detectedSeparator: Character

    /// A chunk of parsed CSV data yielded by the streaming parser.
    public struct Chunk: Sendable {
        /// The chunk's sequential index (0-based).
        public let index: Int
        /// Column definitions (same in every chunk, determined from the header row).
        public let columns: [Csv.Column]
        /// The rows in this chunk.
        public let rows: [Csv.Row]
        /// Warnings generated while parsing this chunk's rows.
        public let warnings: [Warning]
        /// Whether this is the final chunk.
        public let isFinal: Bool
    }
}
