#!/bin/sh

swift package --allow-writing-to-directory docs/Csv2Img \
    generate-documentation --target Csv2Img \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path csv2img \
    --output-path docs/Csv2Img

swift package --allow-writing-to-directory docs/Csv2ImgCmd \
    generate-documentation --target Csv2ImgCmd \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path csv2img \
    --output-path docs/Csv2ImgCmd


cp res/app_privacy_policy.html docs/app_privacy_policy.html
cp README.md docs/index.md