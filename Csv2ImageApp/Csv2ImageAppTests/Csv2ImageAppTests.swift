//
//  Csv2ImageAppTests.swift
//  Csv2ImageAppTests
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import Csv2ImgCore
import PDFKit
import XCTest

@testable import Csv2ImageApp

@MainActor
final class GenerateOutputModelTests: XCTestCase {

    private var directory: URL!
    private var csvURL: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        csvURL = directory.appendingPathComponent("input.csv")
        let csv = "\u{FEFF}name,note\n東京,\"a, b\"\n\nOsaka,\"line1\nline2\"\n\n"
        try csv.write(to: csvURL, atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testGeneratesPdfOnLoad() async throws {
        let model = GenerateOutputModel(url: csvURL, urlType: .local)

        try await waitUntil { model.state.pdfDocument != nil }

        let text = try XCTUnwrap(model.state.pdfDocument?.string)
        for expected in ["name", "note", "東京", "a, b", "Osaka", "line1", "line2"] {
            XCTAssertTrue(text.contains(expected), "\(expected) is missing from the PDF")
        }
        XCTAssertNil(model.state.cgImage)
        XCTAssertNil(model.state.errorMessage)
    }

    func testPaperSizeAndOrientationAreApplied() async throws {
        let model = GenerateOutputModel(url: csvURL, urlType: .local)
        try await waitUntil { model.state.pdfDocument != nil }

        model.update(keyPath: \.size, value: .a4)
        model.update(keyPath: \.orientation, value: .portrait)

        let expected = PdfSize.a4.size(orientation: .portrait)
        try await waitUntil {
            model.state.pdfDocument?.page(at: 0)?.bounds(for: .mediaBox).size == expected
        }
    }

    func testSwitchingToPngGeneratesImage() async throws {
        let model = GenerateOutputModel(url: csvURL, urlType: .local)
        try await waitUntil { model.state.pdfDocument != nil }

        model.update(keyPath: \.exportType, value: .png)

        try await waitUntil { model.state.cgImage != nil }
        XCTAssertNil(model.state.pdfDocument)
        let image = try XCTUnwrap(model.state.cgImage)
        XCTAssertGreaterThan(image.width, 0)
        XCTAssertGreaterThan(image.height, 0)
    }

    func testMissingFileShowsError() async throws {
        let missing = directory.appendingPathComponent("missing.csv")
        let model = GenerateOutputModel(url: missing, urlType: .local)

        try await waitUntil { model.state.errorMessage != nil }
        XCTAssertNil(model.state.pdfDocument)
        XCTAssertNil(model.state.cgImage)
    }

    private func waitUntil(
        timeout: TimeInterval = 20,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline {
                XCTFail("The condition was not met within \(timeout) seconds", file: file, line: line)
                throw CancellationError()
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
