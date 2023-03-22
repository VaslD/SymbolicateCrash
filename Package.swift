// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SymbolicateCrash",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "symbolicate-crash", targets: ["SymbolicateCrash"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
    ],
    targets: [
        .executableTarget(name: "SymbolicateCrash", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Logging", package: "swift-log"),
        ]),
    ]
)
