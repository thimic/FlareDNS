// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlareDNS",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.6.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.13.0"),
        .package(url: "https://github.com/swift-server/swift-backtrace.git", from: "1.3.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "FlareDNS",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ColorizeSwift", package: "ColorizeSwift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Backtrace", package: "swift-backtrace")
            ]
        ),
        .testTarget(
            name: "FlareDNSTests",
            dependencies: ["FlareDNS"]
        ),
    ]
)
