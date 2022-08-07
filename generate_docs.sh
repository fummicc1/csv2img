#!/bin/sh

swift package --allow-writing-to-directory docs/ \
    generate-documentation --target Csv2Img \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path csv2img \
    --output-path docs/

cp res/app_privacy_policy.html docs/