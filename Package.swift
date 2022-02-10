// swift-tools-version:5.5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Apptentive",
    platforms: [ .iOS(.v13) ],
    products: [
        .library(
            name: "Apptentive",
            targets: ["Apptentive"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "Apptentive",
            path: "./Apptentive.xcframework"
        )
    ]
)
