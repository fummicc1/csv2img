![Csv2mg_bg](https://user-images.githubusercontent.com/44002126/173288309-81e336d2-5239-441a-bc6e-2b58bb9da349.png)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffummicc1%2Fcsv2img%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/fummicc1/csv2img) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffummicc1%2Fcsv2img%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/fummicc1/csv2img)

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

![demo](https://user-images.githubusercontent.com/44002126/183291911-13b966f0-c0e2-4a02-a57c-9620edd4b0e1.gif)

# Csv2Img (Library)

Convert Csv into png image.

- [documentation](https://fummicc1.github.io/csv2img/documentation/csv2img/)

## Usage

You cloud convert csv into image in 3 ways.

1. Via raw `String`.

```swift
 let rawCsv = """
 a,b,c
 1,2,3
 4,5,6
 7,8,9
 10,11,12
 """
let csv = Csv.fromString(rawCsv)
let image = csv.cgImage(fontSize: 12)
// or directly get data.
let data = csv.pngData(fontSize: 12)
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
let csv = Csv.fromFile(url)
let data = csv.pngData(fontSize: 12)
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
let csv = Csv.fromURL(url)
let data = csv.pngData(fontSize: 12)
 Output:
 | a  | b  | c  |
 | 1  | 2  | 3  |
 | 4  | 5  | 6  |
 | 7  | 8  | 9  |
 | 10 | 11 | 12 |
```

# Csv2ImgCmd (CLI)

A command line tool which generates png-image from csv. (Using `Csv2Img` library)

- [documentation](https://fummicc1.github.io/Csv2ImgCmd_DocC/documentation/csv2imgcmd/)

## Usage

Coomand line interface using `Csv2Img` library.

If you have a csv file on your computer, you cloud use this flag with `--local`, `-l`.

```shell
./Csv2ImgCmd --local ~/Downloads/sample.csv ./output.csv
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
