# Csv2Img

## Example

1. Build CLI

```shell
swift build -c release
```

2. Convert csv to table with png-format

```shell
./.build/release/Csv2ImgCmd --network "https://raw.githubusercontent.com/fummicc1/csv2img/main/Sources/Csv2ImgCmd/Resources/yolov5x6.csv?token=GHSAT0AAAAAABMYJL6P2RB5LEJXAEC472BMYU2FIUQ" sample.png
```

- first option: decide input data type. choose either `--local` or `--network`
- second argument: input url (if set first-option as `--local`, conform with absolute-path rule.)
- third argument: output path (both relative-path and absolute-path are OK.)

3. Check result

```shell
Succeed generating image from csv!
Output path:  file:///Users/fumiyatanaka/Work/iOSDev/Csv2Img/sample.png
```

Let's check stdout and find your output.

- example output

[input csv is here](https://raw.githubusercontent.com/fummicc1/csv2img/main/Sources/Csv2ImgCmd/Resources/yolov5x6.csv?token=GHSAT0AAAAAABMYJL6OZWFSTEJ5IFOFHYAAYU2FRXA)

|output|
|---|
|![sample](https://user-images.githubusercontent.com/44002126/171876917-e3af6639-bc96-4e6a-9deb-c49b02d93e7c.png)|
