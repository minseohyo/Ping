// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "ProfileFeature",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "ProfileFeature", targets: ["ProfileFeature"])
    ],
    targets: [
        .target(name: "ProfileFeature")
    ]
)

