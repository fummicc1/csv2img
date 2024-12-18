// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let argumentParser: PackageDescription.Package.Dependency = .package(
    url: "https://github.com/apple/swift-argument-parser",
    .upToNextMinor(from: "1.1.0")
)
let docc: PackageDescription.Package.Dependency = .package(
    url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"
)
let swiftSyntax = PackageDescription.Package.Dependency.package(
    url: "https://github.com/swiftlang/swift-syntax",
    from: "510.0.0"
)

let package = Package(
    name: "Csv2Img",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Csv2ImgCore",
            targets: ["Csv2ImgCore"]
        ),
        .library(
            name: "CsvBuilder",
            targets: ["CsvBuilder"]
        ),
        .executable(
            name: "Csv2ImgCmd",
            targets: ["Csv2ImgCmd"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        argumentParser,
        docc,
        swiftSyntax,
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Csv2ImgCore",
            dependencies: []),
        .testTarget(
            name: "Csv2ImgCoreTests",
            dependencies: ["Csv2ImgCore"]
        ),
        .target(
            name: "CsvBuilder",
            dependencies: [
                "Csv2ImgCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "CsvBuilderTests",
            dependencies: ["CsvBuilder"]
        ),
        .executableTarget(
            name: "Csv2ImgCmd",
            dependencies: [
                "Csv2ImgCore",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ]
        ),
    ]
)
