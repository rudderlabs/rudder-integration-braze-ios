// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "SPMConsumer",
    platforms: [.iOS("13.0")],
    products: [
        // A dynamic product verifies linking as well as compiling the integration.
        .library(name: "SPMConsumer", type: .dynamic, targets: ["SPMConsumer"])
    ],
    dependencies: [
        .package(name: "Rudder-Braze", path: "../..")
    ],
    targets: [
        .target(
            name: "SPMConsumer",
            dependencies: [.product(name: "Rudder-Braze", package: "Rudder-Braze")]
        )
    ]
)
