import Foundation
import ArgumentParser
import CoreImage
import Csv2Img
import PDFKit


/// Csv resource type
public enum InputType: EnumerableFlag {
    /// The local input-type
    ///
    /// If you have a csv file on your computer, you cloud use this flag with `--local`, `-l`.
    ///
    /// ```shell
    /// ./Csv2ImgCmd --local ~/Downloads/sample.csv ./output.csv
    /// ```
    case local
    /// The network input-type
    ///
    /// If you would like to convert csv file on the internet, you cloud use this flag with `--network`, `-n`.
    ///
    /// ```shell
    /// ./Csv2ImgCmd --network \
    /// https://raw.githubusercontent.com/fummicc1/csv2img/main/Sources/Csv2ImgCmd/Resources/sample_1.csv \
    /// output.png
    /// ```
    case network

    public static func name(
        for value: InputType
    ) -> NameSpecification {
        switch value {
        case .local:
            return [
                .customLong(
                    "local"
                ),
                .short
            ]
        case .network:
            return [
                .customLong(
                    "network"
                ),
                .short
            ]
        }
    }
}


/// Coomand line interface `Csv2Img`
///
///
/// If you have a csv file on your computer, you cloud use this flag with `--local`, `-l`.
///
/// ```shell
/// ./Csv2ImgCmd --local ~/Downloads/sample.csv ./output.png
/// ```
///
/// If you would like to convert csv file on the internet, you cloud use this flag with `--network`, `-n`.
///
/// ```shell
/// ./Csv2ImgCmd --network \
/// https://raw.githubusercontent.com/fummicc1/csv2img/main/Sources/Csv2ImgCmd/Resources/sample_1.csv \
/// output.png
/// ```
@main
public struct Csv2Img: AsyncParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "csv2img",
            abstract: "Generate image from csv with png-format",
            version: "1.4.0",
            shouldDisplay: true,
            helpNames: [
                .long,
                .short
            ]
        )
    }
    
    @Flag(
        help: "Csv file type. Choose either `local` or `network`"
    )
    public var inputType: InputType
    
    @Option
    public var exportType: Csv.ExportType = .pdf
    
    @Argument(
        help: "Input. csv absolute-path or url on the internet"
    )
    public var input: String
    
    @Argument(
        help: "Output. Specify local path."
    )
    public var output: String

    public init() {
        
    }
    
    public func run() async throws {
        let csv: Csv
        switch inputType {
        case .local:
            csv = try Csv.loadFromDisk(
                URL(
                    fileURLWithPath: input
                )
            )
        case .network:
            guard let url = URL(
                string: input
            ) else {
                print(
                    "Invalid URL: \(input)."
                )
                return
            }
            csv = try Csv.loadFromNetwork(
                url
            )
        }
        let exportable = try await csv.generate(
            fontSize: 12,
            exportType: exportType,
            style: .random()
        ).base
        let outputURL = URL(
            fileURLWithPath: output
        )
        if !FileManager.default.fileExists(
            atPath: output
        ) {
            FileManager.default.createFile(
                atPath: output,
                contents: Data()
            )
        }
        switch exportable {
        case let pdf as PDFDocument:
            let isSuccessful = pdf.write(
                to: outputURL
            )
            if !isSuccessful {
                throw PdfMakingError.failedToSavePdf(
                    at: outputURL.absoluteString
                )
            }
            print(
                "Succeed generating pdf from csv!"
            )
        case let image as CGImage:
            let data = image.convertToData()
            try data?.write(
                to: outputURL
            )
            print(
                "Succeed generating image from csv!"
            )
        default:
            fatalError(
                "unsupported exportable data."
            )
        }
        print(
            "Output path: ",
            outputURL.absoluteString
        )
    }
}

extension Csv.ExportType: ExpressibleByArgument {
}
