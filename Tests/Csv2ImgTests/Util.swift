//
//  Util.swift
//  Csv2Img
//
//  Created by Fumiya Tanaka on 2024/09/23.
//

import XCTest

func getRelativeFilePathFromPackageSource(path: String) -> URL {
    let packageRootPath = URL(fileURLWithPath: #file).pathComponents
        .prefix(while: { $0 != "Tests" }).joined(
            separator: "/"
        ).dropFirst()
    let fileURLPath = [String(packageRootPath), path].joined(separator: "/")
    let fileURL = URL(fileURLWithPath: fileURLPath)
    XCTAssertTrue(
        FileManager.default.fileExists(atPath: fileURL.path),
        "\(fileURLPath) does not exists."
    )
    return fileURL
}
