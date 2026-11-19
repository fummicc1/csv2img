import XCTest

@testable import Csv2ImgCmd

final class Csv2ImgTests: XCTestCase {

    private var workingDirectory: URL!
    private var previousDirectory: String!
    private var inputPath: String!
    private var pdfPath: String!

    override func setUpWithError() throws {
        workingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
        let input = workingDirectory.appendingPathComponent("input.csv")
        try "a,b\n1,2\n".write(to: input, atomically: true, encoding: .utf8)
        inputPath = input.path
        pdfPath = workingDirectory.appendingPathComponent("out.pdf").path

        previousDirectory = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(workingDirectory.path)
    }

    override func tearDownWithError() throws {
        FileManager.default.changeCurrentDirectoryPath(previousDirectory)
        try FileManager.default.removeItem(at: workingDirectory)
    }

    // MARK: - Output path

    func testOutputWithoutDirectoryIsAccepted() throws {
        XCTAssertNoThrow(try Csv2Img.parse([inputPath, "--export-type", "png", "--output", "out.png"]))
    }

    func testOutputInMissingDirectoryIsRejected() {
        XCTAssertThrowsError(
            try Csv2Img.parse([inputPath, "--export-type", "png", "--output", "missing/out.png"])
        )
    }

    // MARK: - Version

    func testVersionNeedsNoInput() {
        XCTAssertThrowsError(try Csv2Img.parse(["--version"])) { error in
            XCTAssertEqual(Csv2Img.exitCode(for: error), .success)
            XCTAssertEqual(Csv2Img.message(for: error), Csv2Img.version)
        }
    }

    func testShortVersionFlagIsNotOffered() {
        XCTAssertFalse(Csv2Img.helpMessage().contains("-v,"))
    }

    // MARK: - PDF options

    func testUnknownOrientationIsRejected() {
        XCTAssertThrowsError(
            try Csv2Img.parse([inputPath, "--output", pdfPath, "--orientation", "sideways"])
        )
    }

    func testUnknownPaperSizeIsRejected() {
        XCTAssertThrowsError(
            try Csv2Img.parse([inputPath, "--output", pdfPath, "--paper-size", "z9"])
        )
    }

    func testPdfOptionsIgnoreCase() throws {
        let command = try Csv2Img.parse(
            [inputPath, "--output", pdfPath, "--paper-size", "A4", "--orientation", "Portrait"]
        )
        XCTAssertEqual(command.paperSize, .a4)
        XCTAssertEqual(command.orientation, .portrait)
    }
}
