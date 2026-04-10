// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CorePersistence",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CorePersistence", targets: ["CorePersistence"])
    ],
    targets: [
        .target(name: "CorePersistence")
    ]
)

