// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUtilities",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftUtilities",
            targets: ["SwiftUtilities"]
        )
    ],
    targets: [
        .target(name: "SwiftUtilities")
    ]
)
