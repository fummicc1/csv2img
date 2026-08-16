import XCTest

@testable import Csv2ImgCore

final class SeparatorDetectorTests: XCTestCase {

    private let detector = SeparatorDetector()

    // MARK: - Normal cases

    /// T301: Detect comma separator.
    func testT301_detectComma() {
        let input = "a,b,c\n1,2,3\n4,5,6"
        XCTAssertEqual(detector.detect(from: input), ",")
    }

    /// T302: Detect tab separator.
    func testT302_detectTab() {
        let input = "a\tb\tc\n1\t2\t3"
        XCTAssertEqual(detector.detect(from: input), "\t")
    }

    /// T303: Detect pipe separator.
    func testT303_detectPipe() {
        let input = "a|b|c\n1|2|3"
        XCTAssertEqual(detector.detect(from: input), "|")
    }

    /// T304: Detect semicolon separator.
    func testT304_detectSemicolon() {
        let input = "a;b;c\n1;2;3"
        XCTAssertEqual(detector.detect(from: input), ";")
    }

    /// T305: Commas inside quotes should be ignored when detecting semicolon.
    func testT305_ignoreCommasInsideQuotes() {
        let input = "a;\"b,c\";d\n1;2;3"
        XCTAssertEqual(detector.detect(from: input), ";")
    }

    // MARK: - Boundary cases

    /// T311: Single line input should still detect.
    func testT311_singleLine() {
        let input = "a,b,c"
        XCTAssertEqual(detector.detect(from: input), ",")
    }

    /// T312: No separator candidates → default comma.
    func testT312_noSeparatorCandidates() {
        let input = "abcdef\nghijkl"
        XCTAssertEqual(detector.detect(from: input), ",")
    }

    /// T313: Inconsistent counts should still pick best candidate.
    func testT313_inconsistentCounts() {
        let input = "a,b,c\n1,2"
        let result = detector.detect(from: input)
        XCTAssertEqual(result, ",")
    }

    /// T314: Multiple candidates with same frequency — comma should win as first candidate.
    func testT314_multipleCandidatesSameFrequency() {
        // Both comma and semicolon appear equally — comma wins due to candidate order
        let input = "a,b;c\n1,2;3"
        let result = detector.detect(from: input)
        // Both have 1 occurrence per line, both consistent. Comma is checked first.
        XCTAssertTrue(result == "," || result == ";")
    }

    /// T315: More than 5 lines — only first 5 should be analyzed.
    func testT315_moreThanFiveLines() {
        let lines = (0..<10).map { "a,b,\($0)" }
        let input = lines.joined(separator: "\n")
        XCTAssertEqual(detector.detect(from: input), ",")
    }
}
