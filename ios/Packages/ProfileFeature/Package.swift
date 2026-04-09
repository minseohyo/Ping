// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ProfileFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProfileFeature", targets: ["ProfileFeature"])
    ],
    targets: [
        .target(name: "ProfileFeature")
    ]
)

