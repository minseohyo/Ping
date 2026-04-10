// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CoreModels",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"])
    ],
    targets: [
        .target(name: "CoreModels")
    ]
)

