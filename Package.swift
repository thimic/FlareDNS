// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlareDNS",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
//        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FlareDNS",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ColorizeSwift", package: "ColorizeSwift"),
            ],
            exclude: ["requests.swift"]),
//            dependencies: ["PromiseKit"]),
        .testTarget(
            name: "FlareDNSTests",
            dependencies: ["FlareDNS"],
            exclude: ["requests.swift"]),
    ]
)
