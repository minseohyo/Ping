// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CoreNetworking",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CoreNetworking", targets: ["CoreNetworking"])
    ],
    dependencies: [
        .package(path: "../CoreModels")
    ],
    targets: [
        .target(
            name: "CoreNetworking",
            dependencies: ["CoreModels"]
        )
    ]
)

