#!/bin/sh

swift package --allow-writing-to-directory docs \
    generate-documentation --target Csv2Img \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path csv2img \
    --output-path docs


swift package --allow-writing-to-directory ../Csv2ImgCmd_DocC/docs \
    generate-documentation --target Csv2ImgCmd \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path Csv2ImgCmd_DocC \
    --output-path ../Csv2ImgCmd_DocC/docs

cp res/app_privacy_policy.html docs/app_privacy_policy.html