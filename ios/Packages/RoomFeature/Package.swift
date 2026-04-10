// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "RoomFeature",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "RoomFeature", targets: ["RoomFeature"])
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CoreUI")
    ],
    targets: [
        .target(
            name: "RoomFeature",
            dependencies: ["CoreModels", "CoreNetworking", "CoreUI"]
        )
    ]
)

