//
//  File.swift
//  
//
//  Created by Fumiya Tanaka on 2022/06/03.
//

import Foundation
import ArgumentParser
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
public struct Csv2Img: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "csv2img",
            abstract: "Generate table from csv with png-format",
            version: "0.0.1",
            shouldDisplay: true,
            helpNames: [.long, .short]
        )
    }

    @Flag(help: "Input type. Choose either `local` or `network`")
    public var inputType: InputType

    @Argument(help: "Input. csv absolute-path.")
    public var data: String

    @Argument(help: "Output. Specify path.")
    public var output: String

    public init() { }

    public func run() throws {
        let imageMaker = ImageMaker(
            fontSize: 12
        )
        let csv: Csv
        switch inputType {
        case .local:
            csv = try Csv.fromFile(URL(fileURLWithPath: data))
        case .network:
            guard let url = URL(string: data) else {
                print("Invalid URL: \(data).")
                return
            }
            csv = try Csv.fromURL(url)
        }
        let data = imageMaker.make(csv: csv)
        let outputURL = URL(fileURLWithPath: output)
        if !FileManager.default.fileExists(atPath: output) {
            FileManager.default.createFile(atPath: output, contents: data)
        } else {
            try data!.write(to: outputURL)
        }
        print("Succeed generating image from csv!")
        print("Output path: ", outputURL.absoluteString)
    }
}

Csv2Img.main()
