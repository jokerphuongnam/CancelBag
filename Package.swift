// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CancelBag",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "CancelBag", targets: ["CancelBag"]),
    ],
    targets: [
        .target(
            name: "CancelBag",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "CancelBagTests",
            dependencies: ["CancelBag"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
