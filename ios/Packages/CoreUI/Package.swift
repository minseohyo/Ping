// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CoreUI", targets: ["CoreUI"])
    ],
    dependencies: [
        .package(path: "../CoreModels")
    ],
    targets: [
        .target(name: "CoreUI", dependencies: ["CoreModels"])
    ]
)

