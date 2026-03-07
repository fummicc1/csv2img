import Foundation

/// Detects the most likely separator character from the first few lines of a CSV/TSV/etc. string.
public struct SeparatorDetector: Sendable {

    /// Candidate separator characters.
    public static let candidates: [Character] = [",", "\t", "|", ";"]

    public init() {}

    /// Detect the separator from the input string by analyzing the first few lines.
    /// - Parameter string: The input string to analyze.
    /// - Returns: The detected separator character. Falls back to `,` if undetermined.
    public func detect(from string: String) -> Character {
        let lines = extractFirstLines(from: string, count: 5)
        guard !lines.isEmpty else { return "," }

        var bestCandidate: Character = ","
        var bestScore = 0

        for candidate in Self.candidates {
            let counts = lines.map { countOccurrences(of: candidate, in: $0) }

            // All lines must have at least 1 occurrence
            guard let minCount = counts.min(), minCount >= 1 else { continue }

            // Check consistency: all lines should have the same count
            let isConsistent = Set(counts).count == 1

            let totalCount = counts.reduce(0, +)

            if isConsistent && totalCount > bestScore {
                bestScore = totalCount
                bestCandidate = candidate
            } else if !isConsistent && bestScore == 0 && totalCount > 0 {
                // Fallback: if no consistent candidate found, pick best inconsistent one
                if totalCount > bestScore {
                    bestScore = totalCount
                    bestCandidate = candidate
                }
            }
        }

        return bestCandidate
    }

    // MARK: - Private

    /// Extract up to `count` lines from the string, respecting quoted fields.
    private func extractFirstLines(from string: String, count: Int) -> [String] {
        var lines: [String] = []
        var currentLine = ""
        var inQuotes = false
        var index = string.startIndex

        while index < string.endIndex && lines.count < count {
            let char = string[index]

            if char == "\"" {
                inQuotes.toggle()
                currentLine.append(char)
            } else if !inQuotes && (char == "\n" || char == "\r") {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = ""
                }
                // Consume \r\n as one newline
                if char == "\r" {
                    let next = string.index(after: index)
                    if next < string.endIndex && string[next] == "\n" {
                        index = next
                    }
                }
            } else {
                currentLine.append(char)
            }

            index = string.index(after: index)
        }

        if !currentLine.isEmpty && lines.count < count {
            lines.append(currentLine)
        }

        return lines
    }

    /// Count occurrences of a character outside of quoted regions.
    private func countOccurrences(of char: Character, in line: String) -> Int {
        var count = 0
        var inQuotes = false

        for c in line {
            if c == "\"" {
                inQuotes.toggle()
            } else if c == char && !inQuotes {
                count += 1
            }
        }

        return count
    }
}
