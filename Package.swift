// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let argumentParser: PackageDescription.Package.Dependency = .package(
    url: "https://github.com/apple/swift-argument-parser",
    .upToNextMinor(from: "1.1.0")
)

let package = Package(
    name: "Csv2Img",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
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
        argumentParser
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
            dependencies: [
                "Csv2Img",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        )
    ]
)
