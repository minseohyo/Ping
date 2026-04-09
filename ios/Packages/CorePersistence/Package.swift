// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CorePersistence",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CorePersistence", targets: ["CorePersistence"])
    ],
    targets: [
        .target(name: "CorePersistence")
    ]
)

