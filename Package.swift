// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUIFormsKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SwiftUIFormsKit", targets: ["SwiftUIFormsKit"]),
    ],
    targets: [
        .target(
            name: "SwiftUIFormsKit",
            path: "Sources/SwiftUIFormsKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftUIFormsKitTests",
            dependencies: ["SwiftUIFormsKit"]
        )
    ]
)
