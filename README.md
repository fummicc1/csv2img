![Csv2mg_bg](https://user-images.githubusercontent.com/44002126/173288309-81e336d2-5239-441a-bc6e-2b58bb9da349.png)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffummicc1%2Fcsv2img%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/fummicc1/csv2img) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffummicc1%2Fcsv2img%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/fummicc1/csv2img) <img src="https://github.com/fummicc1/csv2img/actions/workflows/lib.yml/badge.svg"> <img src="https://github.com/fummicc1/csv2img/actions/workflows/builder.yml/badge.svg"> <img src="https://github.com/fummicc1/csv2img/actions/workflows/command.yml/badge.svg">

# Csv2ImageApp

Convert Csv into png image.

<a href="https://apps.apple.com/jp/app/csv-converter-app/id1628273936?mt=12"><img src="https://raw.github.com/fummicc1/csv2img/1.9.0/res/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg?sanitize=true"></a>

## Demo

### iOS App

https://github.com/user-attachments/assets/a9a7847e-7edc-4e28-b918-66de4b992aa3

### MacOS App

https://github.com/user-attachments/assets/9b6f5064-ab6e-4897-a0ab-cf5f104e3bbe

# Installation

Add the following to your `Package.swift` file:

```swift
.package(url: "https://github.com/fummicc1/csv2img.git", from: "1.9.1"),
```

# Csv2ImgCore (Library)

Convert Csv into png image.

- [documentation](https://fummicc1.github.io/csv2img/documentation/csv2imgcore/)

## Installation of Csv2Img

Add the following to your `Package.swift` file:

```swift
.product(name: "Csv2Img", package: "csv2img"),
```

## Usage of Csv2Img

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

### Output Image

![sample](https://user-images.githubusercontent.com/44002126/186811765-ecc16ca5-9121-47ee-a5a6-a51ac181abd5.png)

# CsvBuilder (Helper Library for Csv2Img)

A helper library to generate `Csv` in Csv2Img library.

## Installation of CsvBuilder

Add the following to your `Package.swift` file:

```swift
.product(name: "CsvBuilder", package: "csv2img"),
```

## Usage of CsvBuilder

1. Define custom type that conforms to `CsvComposition`.

```swift
import Foundation
import Csv2ImgCore


public struct CsvCompositionExample: CsvComposition {
    @CsvRows(column: "age")
    public var ages: [String]

    @CsvRows(column: "name")
    public var names: [String]

    public init() { }
}
```

2. Build `Csv`

```swift
let composition: CsvCompositionExample = .init()
composition.ages.append(contentsOf: ["98", "99", "100"])
composition.names.append(contentsOf: ["Yamada", "Tanaka", "Sato"])
let csv = try! composition.build()
```

or you can write different way like the below.

```swift
let yamada = Csv.Row(index: 0, values: ["98", "Yamada"])
let tanaka = Csv.Row(index: 1, values: ["99", "Tanaka"])
let sato = Csv.Row(index: 2, values: ["100", "Sato"])
let csv = try! CsvCompositionParser.parse(type: CsvCompositionExample.self, rows: [yamada, tanaka, sato,])
```

| Result                                                                                                                                                                     |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <img width="392" alt="スクリーンショット 2022-08-26 12 54 22" src="https://user-images.githubusercontent.com/44002126/186814170-0c33013e-c138-4ed5-a34c-5d45dc8ac0c0.png"> |

# Csv2ImgCmd (CLI)

A command line tool which generates png-image from csv. (Using `Csv2Img` library)

- [documentation](https://fummicc1.github.io/Csv2ImgCmd_DocC/documentation/csv2imgcmd/)

## Installation of Csv2ImgCmd

Add the following to your `Package.swift` file:

```swift
.product(name: "Csv2ImgCmd", package: "csv2img"),
```

## Usage of Csv2ImgCmd

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
