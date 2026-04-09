// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatchingFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MatchingFeature", targets: ["MatchingFeature"])
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../CoreNetworking")
    ],
    targets: [
        .target(
            name: "MatchingFeature",
            dependencies: ["CoreModels", "CoreNetworking"]
        )
    ]
)

