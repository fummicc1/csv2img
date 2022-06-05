# Csv2Img

Convert Csv into png image.

## Overview

Csv2Image is static library to convert csv data into table with png-format.

---

# Csv2ImgCmd

A command line tool which generates png-image from csv. (Using `Csv2Img` library)

## Overview

`Csv2ImgCmd` is CLI tool to generate image from csv. 

## Usage

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

[input csv folder](https://github.com/fummicc1/csv2img/tree/main/Sources/Csv2ImgCmd/Resources)

|sample_1|sample_2|yolov5x6|
|---|---|---|
|![sample](https://user-images.githubusercontent.com/44002126/171883872-93084973-4a67-469b-834c-19d3c6e42573.png)|![sample2](https://user-images.githubusercontent.com/44002126/171883971-88a161ef-7544-46a3-98d8-4ea00c6ae7b9.png)|![sample](https://user-images.githubusercontent.com/44002126/171876917-e3af6639-bc96-4e6a-9deb-c49b02d93e7c.png)|
