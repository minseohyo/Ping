// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "AuthFeature",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "AuthFeature", targets: ["AuthFeature"])
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CorePersistence")
    ],
    targets: [
        .target(
            name: "AuthFeature",
            dependencies: ["CoreModels", "CoreNetworking", "CorePersistence"]
        )
    ]
)

