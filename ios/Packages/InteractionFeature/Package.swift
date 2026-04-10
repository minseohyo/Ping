// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "InteractionFeature",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "InteractionFeature", targets: ["InteractionFeature"])
    ],
    targets: [
        .target(name: "InteractionFeature")
    ]
)

