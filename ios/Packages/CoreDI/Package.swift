// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CoreDI",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CoreDI", targets: ["CoreDI"])
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CorePersistence")
    ],
    targets: [
        .target(
            name: "CoreDI",
            dependencies: ["CoreModels", "CoreNetworking", "CorePersistence"]
        )
    ]
)

