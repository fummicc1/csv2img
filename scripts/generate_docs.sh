#!/bin/sh

swift package --allow-writing-to-directory docs \
    generate-documentation \
    --target Csv2ImgCore --target Csv2ImgCmd --target CsvBuilder \
    --disable-indexing \
    --transform-for-static-hosting \
    --enable-experimental-combined-documentation \
    --hosting-base-path csv2img \
    --output-path docs

cp res/app_privacy_policy.html docs/app_privacy_policy.html