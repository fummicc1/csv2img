#!/bin/sh

swift package --allow-writing-to-directory docs \
    generate-documentation --target Csv2ImgCmd \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path csv2img \
    --output-path docs


cp res/app_privacy_policy.html docs/app_privacy_policy.html
cp README.md docs/index.md