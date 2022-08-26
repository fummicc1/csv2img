![Csv2mg_bg](https://user-images.githubusercontent.com/44002126/173288309-81e336d2-5239-441a-bc6e-2b58bb9da349.png)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffummicc1%2Fcsv2img%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/fummicc1/csv2img) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffummicc1%2Fcsv2img%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/fummicc1/csv2img)

<img src="https://github.com/fummicc1/csv2img/actions/workflows/lib.yml/badge.svg">
<img src="https://github.com/fummicc1/csv2img/actions/workflows/builder.yml/badge.svg">
<img src="https://github.com/fummicc1/csv2img/actions/workflows/command.yml/badge.svg">

# Csv2ImageApp

Convert Csv into png image.

<a href="https://apps.apple.com/jp/app/csv-converter-app/id1628273936?mt=12"><img src="https://raw.github.com/fummicc1/csv2img/1.3.2/res/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg?sanitize=true"></a>

## iOS App

Because this app has been developed with Xcode14 and under multiplatform feature which was annouced at WWDC22, I can't publish this app on the AppStore. Alternatively I prepared TestFlight version as for iOS app.

- [TestFlight for iOS App](https://testflight.apple.com/join/w8jZU9Jq)

### Demo

<img src="https://user-images.githubusercontent.com/44002126/184648376-0269aa36-210e-41be-b6ee-567e7a10bd88.gif" width=320>

## MacOS App

### Demo

![demo2](https://user-images.githubusercontent.com/44002126/186102558-5176d16a-a0fa-4e27-bf73-0871f282f1d2.gif)

# Csv2Img (Library)

Convert Csv into png image.

- [documentation](https://fummicc1.github.io/csv2img/documentation/csv2img/)

## Usage

You cloud convert csv into image / pdf in 3 ways.

1. Via raw `String`.

```swift
 let rawCsv = """
 a,b,c
 1,2,3
 4,5,6
 7,8,9
 10,11,12
 """
let csv = Csv.loadFromString(rawCsv)
let image = try await csv.generate(exportType: .png)
 Output:
 | a  | b  | c  |
 | 1  | 2  | 3  |
 | 4  | 5  | 6  |
 | 7  | 8  | 9  |
 | 10 | 11 | 12 |
```

2. Via Local file.

```swift
 let rawCsv = """
 a,b,c
 1,2,3
 4,5,6
 7,8,9
 10,11,12
 """
let url = URL(
    fileURLWithPath: "/Users/fumiyatanaka/Downloads/sample.csv"
)
rawCsv.data(using: .utf8)?.write(to: url)
// ----- ↑Just prepared for explanation. -----
let csv = Csv.loadFromDisk(url)
let data = try await csv.generate(fontSize: 12, exportType: .png)
 Output:
 | a  | b  | c  |
 | 1  | 2  | 3  |
 | 4  | 5  | 6  |
 | 7  | 8  | 9  |
 | 10 | 11 | 12 |
```

3. Via network resource

```swift
let rawCsv = """
 a,b,c
 1,2,3
 4,5,6
 7,8,9
 10,11,12
 """
let url = URL(
    string: "https://raw.githubusercontent.com/fummicc1/csv2img/main/Fixtures/sample_1.csv"
)
// ----- ↑Just prepared for explanation. -----
let csv = Csv.loadFromNetwork(url)
let data = try await csv.generate(fontSize: 12, exportType: .png)
 Output:
 | a  | b  | c  |
 | 1  | 2  | 3  |
 | 4  | 5  | 6  |
 | 7  | 8  | 9  |
 | 10 | 11 | 12 |
```

#### Output Image

![sample](https://user-images.githubusercontent.com/44002126/186811765-ecc16ca5-9121-47ee-a5a6-a51ac181abd5.png)

# CsvBuilder (Helper Library for Csv2Img)

A helper library to generate `Csv` in Csv2Img library.

## How to use

1. Define custom type which conform to `CsvComposition`.

```swift
import Foundation
import Csv2Img


public struct ExampleComposition: CsvComposition {
    @CsvRows(column: "age")
    public var ages: [String]

    @CsvRows(column: "name")
    public var names: [String]

    public init() { }
}
```

2. Build `Csv`

```swift
let composition: ExampleComposition = .init()
composition.ages.append(contentsOf: ["98", "99", "100"])
composition.names.append(contentsOf: ["Yamada", "Tanaka", "Sato"])
let csv = try! composition.build()
```

| Result |
| ------ |

|
<img width="392" alt="スクリーンショット 2022-08-26 12 54 22" src="https://user-images.githubusercontent.com/44002126/186814170-0c33013e-c138-4ed5-a34c-5d45dc8ac0c0.png"> |

# Csv2ImgCmd (CLI)

A command line tool which generates png-image from csv. (Using `Csv2Img` library)

- [documentation](https://fummicc1.github.io/Csv2ImgCmd_DocC/documentation/csv2imgcmd/)

## Usage

Coomand line interface using `Csv2Img` library.

If you have a csv file on your computer, you cloud use this flag with `--local`, `-l`.

```shell
./Csv2ImgCmd --local ~/Downloads/sample.csv ./output.png
```

If you would like to convert csv file on the internet, you cloud use this flag with `--network`, `-n`.

```shell
./Csv2ImgCmd --network \
https://raw.githubusercontent.com/fummicc1/csv2img/main/Sources/Csv2ImgCmd/Resources/sample_1.csv \
output.png
```

# Contributing

Pull requests, bug reports and feature requests are welcome 🚀

# License

[MIT LICENSE](https://github.com/fummicc1/csv2img/blob/main/LICENSE)
