// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rudder-Braze",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "Rudder-Braze",
            targets: ["Rudder-Braze"]),
    ],
    dependencies: [
        .package(name: "braze-swift-sdk", url: "https://github.com/braze-inc/braze-swift-sdk-prebuilt-static", .exact("9.3.0")),
        .package(name: "Rudder", url: "https://github.com/rudderlabs/rudder-sdk-ios", "1.26.0"..<"2.0.0")
    ],
    targets: [
        .target(
            name: "Rudder-Braze",
            dependencies: [
                .product(name: "BrazeKit", package: "braze-swift-sdk"),
                .product(name: "Rudder", package: "Rudder"),
            ],
            path: "Rudder-Braze",
            sources: ["Classes/"],
            publicHeadersPath: "Classes/",
            cSettings: [
                .headerSearchPath("Classes/")
            ]
        )
    ]
)
