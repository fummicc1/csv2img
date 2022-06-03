//
//  File.swift
//  
//
//  Created by Fumiya Tanaka on 2022/06/03.
//

import Foundation
import ArgumentParser
import Csv2Img

let testCsv = """
,name,xmin,ymin,xmax,ymax
0,car,0.0,0.5358886082967123,1.0,1.0
1,person,0.0,0.5359219868977865,1.0,1.0
2,traffic_light,0.21951253414154054,0.15762767791748047,0.9994660377502441,0.8060480753580729
3,bicycle,0.1556121826171875,0.6257188796997071,0.7293229103088379,1.0
4,motorcycle,0.0,0.6452130635579427,0.898946475982666,1.0
5,truck,0.0011012136936187744,0.5136067072550455,1.0,1.0
6,bus,0.08284066915512085,0.4859299341837565,1.0,1.0
7,surfboard,0.8881638526916504,0.9177943547566731,0.9477010726928711,1.0
8,fire hydrant,0.04979668259620666,0.699217414855957,0.7389864444732666,1.0
9,train,0.27674896717071534,0.5813900629679362,0.7931543350219726,0.9962208429972331
10,cow,0.41159906387329104,0.9000104268391927,0.6436811447143554,1.0
11,dog,0.3863001108169556,0.6684404373168945,0.41945762634277345,0.7598814010620117
12,suitcase,0.34842376708984374,0.8443502426147461,0.6400514602661133,1.0
13,bench,0.0027508974075317384,0.9066076278686523,0.20663852691650392,0.999391746520996
14,parking meter,0.2383899688720703,0.7166788736979167,0.5004729270935059,0.8884522755940755
15,umbrella,0.25936431884765626,0.5126305262247721,0.5550491809844971,0.9992945353190105
16,horse,0.5073151588439941,0.8091239929199219,0.5564560890197754,0.9650737762451171
"""

public enum InputType: EnumerableFlag {
    case local
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
