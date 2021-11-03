// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "RudderBraze",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "RudderBraze", targets: ["RudderBraze"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rudderlabs/rudder-sdk-ios.git", from: "1.1.1"),
        .package(url: "https://github.com/Appboy/appboy-ios-sdk.git", from: "4.3.2"),
    ],
    targets: [
        .target(
            name: "RudderBraze",
            dependencies: [
                .product(name: "Rudder", package: "rudder-sdk-ios"),
                .product(name: "AppboyUI", package: "appboy-ios-sdk"),
            ],
            path: "Rudder-Braze",
            sources: ["Classes"],
            publicHeadersPath: "Classes"
        )
    ]
)
