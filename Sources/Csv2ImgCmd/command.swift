import ArgumentParser
import CoreImage
import Csv2ImgCore
import Foundation
import PDFKit

/// Coomand line interface `Csv2Img`
///
///
/// If you have a csv file on your computer, you cloud use this flag with `--local`, `-l`.
///
/// ```shell
/// ./Csv2ImgCmd ~/Downloads/sample.csv --output ./output.png
/// ```
///
/// If you would like to convert csv file on the internet, you cloud just pass the url with prefix https:// or http:// such as https://example.com/
///
/// ```shell
/// ./Csv2ImgCmd https://raw.githubusercontent.com/fummicc1/csv2img/main/Fixtures/sample_1.csv \
/// --output output.png
/// ```
@main
public struct Csv2Img: AsyncParsableCommand {

    static let version: String = "1.9.1"

    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "csv2img",
            abstract: "Generate image from csv with png-format",
            version: version,
            shouldDisplay: true,
            helpNames: [
                .long,
                .short,
            ]
        )
    }

    @Option(
        name: .shortAndLong,
        help: "Export type. Choose either `pdf` or `png`"
    )
    public var exportType: Csv.ExportType = .pdf

    @Argument(
        help: "Input. csv absolute-path or url on the internet"
    )
    public var input: String

    @Option(
        name: .shortAndLong,
        help: "Output. Specify local path."
    )
    public var output: String

    @Flag(
        name: .shortAndLong,
        help: "Print the version of csv2img"
    )
    public var version: Bool = false

    @Option(
        name: .shortAndLong,
        help: "Specify the font size"
    )
    public var fontSize: Double = 12

    @Option(
        name: .shortAndLong,
        help: "Paper size for PDF export (a4, b4, b3, etc). Default is b3"
    )
    public var paperSize: String = "b3"

    @Option(
        name: .shortAndLong,
        help: "Page orientation for PDF (portrait/landscape). Default is landscape"
    )
    public var orientation: String = "landscape"

    public init() {}

    public func validate() throws {
        if !input.hasPrefix("http") && !FileManager.default.fileExists(atPath: input) {
            throw ValidationError("Input file does not exist at path: \(input)")
        }

        let outputDir = (output as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: outputDir) {
            throw ValidationError("Output directory does not exist: \(outputDir)")
        }

        let outputExtension = (output as NSString).pathExtension.lowercased()
        switch exportType {
        case .pdf where outputExtension != "pdf":
            throw ValidationError("Output file extension should be .pdf when export type is PDF")
        case .png where outputExtension != "png":
            throw ValidationError("Output file extension should be .png when export type is PNG")
        default:
            break
        }
    }

    public func run() async throws {
        if version {
            print("csv2img version \(Self.version)")
            return
        }

        print("🚀 Starting conversion process...")

        let csv: Csv
        if input.hasPrefix("http://") || input.hasPrefix("https://") {
            print("📥 Downloading CSV from URL...")
            guard let url = URL(string: input) else {
                throw ValidationError("Invalid URL: \(input)")
            }
            csv = try Csv.loadFromNetwork(url)
        } else {
            print("📂 Reading local CSV file...")
            csv = try Csv.loadFromDisk(URL(fileURLWithPath: input))
        }

        print("🔄 Processing CSV data...")

        if exportType == .pdf {
            let orientation: PdfSize.Orientation =
                self.orientation.lowercased() == "portrait" ? .portrait : .landscape
            let size = PdfSize(rawValue: paperSize.lowercased()) ?? .b3

            await csv.update(
                pdfMetadata: .init(
                    size: size,
                    orientation: orientation
                ))
            print("📄 Configured PDF settings: \(paperSize) - \(orientation)")
        }

        print("⚙️ Generating \(exportType) file...")

        let exportable = try await csv.generate(
            fontSize: fontSize,
            exportType: exportType,
            style: .random()
        ).base

        print("💾 Saving file...")
        try await saveExportable(exportable, to: URL(fileURLWithPath: output))

        print("\n✅ Successfully generated \(exportType) file!")
        print("📁 Output: \(output)")
    }

    private func saveExportable(_ exportable: any CsvExportable, to url: URL) async throws {
        switch exportable {
        case let pdf as PDFDocument:
            if !pdf.write(to: url) {
                throw PdfMakingError.failedToSavePdf(at: url.absoluteString)
            }
        case let image as CGImage:
            guard let data = image.convertToData() else {
                throw ValidationError("Failed to convert image to data")
            }
            try data.write(to: url)
        default:
            throw ValidationError("Unsupported export type")
        }
    }
}

extension Csv.ExportType: ExpressibleByArgument {
}
