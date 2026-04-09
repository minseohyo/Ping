// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InteractionFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InteractionFeature", targets: ["InteractionFeature"])
    ],
    targets: [
        .target(name: "InteractionFeature")
    ]
)

