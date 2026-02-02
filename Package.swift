// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftUIFormsKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "SwiftUIFormsKit",
            targets: ["SwiftUIFormsKit"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIFormsKit",
            path: "Sources/SwiftUIFormsKit"
        ),
        .testTarget(
            name: "SwiftUIFormsKitTests",
            dependencies: ["SwiftUIFormsKit"]
        )
    ]
)
