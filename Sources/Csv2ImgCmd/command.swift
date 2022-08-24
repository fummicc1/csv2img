import Foundation
import ArgumentParser
import CoreImage
import Csv2Img


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

    public static func name(for value: InputType) -> NameSpecification {
        switch value {
        case .local:
            return [.customLong("local"), .short]
        case .network:
            return [.customLong("network"), .short]
        }
    }
}


/// Coomand line interface `Csv2Img`
///
///
/// If you have a csv file on your computer, you cloud use this flag with `--local`, `-l`.
///
/// ```shell
/// ./Csv2ImgCmd --local ~/Downloads/sample.csv ./output.csv
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
            helpNames: [.long, .short]
        )
    }

    @Flag(help: "Csv file type. Choose either `local` or `network`")
    public var inputType: InputType

    @Argument(help: "Input. csv absolute-path.")
    public var input: String

    @Argument(help: "Output. Specify path.")
    public var output: String

    public init() { }

    public func run() async throws {
        let csv: Csv
        switch inputType {
        case .local:
            csv = try await Csv().loadFromDisk(URL(fileURLWithPath: input))
        case .network:
            guard let url = URL(string: input) else {
                print("Invalid URL: \(input).")
                return
            }
            csv = try await Csv().loadFromNetwork(url)
        }
        let image = try await csv.generate(fontSize: 12, exportType: .png).base as! CGImage
        let data = image.convertToData()
        let outputURL = URL(fileURLWithPath: output)
        if !FileManager.default.fileExists(atPath: output) {
            FileManager.default.createFile(atPath: output, contents: data)
        } else {
            try data?.write(to: outputURL)
        }
        print("Succeed generating image from csv!")
        print("Output path: ", outputURL.absoluteString)
    }
}
