// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreDI",
    platforms: [.iOS(.v17)],
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

