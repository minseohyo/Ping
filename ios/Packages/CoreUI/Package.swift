// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CoreUI",
    platforms: [.iOS(.v16)],
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

