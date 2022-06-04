// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Csv2Img",
    platforms: [.macOS(.v10_14)],
    products: [
        .library(
            name: "Csv2Img_Csv2ImgCmd",
            targets: [
                "Csv2Img", "Csv2ImgCmd"
            ]
        ),
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Csv2Img",
            targets: ["Csv2Img"]
        ),
        .executable(
            name: "Csv2ImgCmd",
            targets: ["Csv2ImgCmd"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            name: "ArgumentParser",
            url: "https://github.com/apple/swift-argument-parser",
            from: .init(1, 1, 2)
        ),
        .package(
            url: "https://github.com/apple/swift-docc-plugin.git",
            from: "1.0.0"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Csv2Img",
            dependencies: []),
        .testTarget(
            name: "Csv2ImgTests",
            dependencies: ["Csv2Img"]),
        .executableTarget(
            name: "Csv2ImgCmd",
            dependencies: ["Csv2Img", "ArgumentParser"]            
        )
    ]
)
