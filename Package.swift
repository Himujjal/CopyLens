// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CopyLens",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CopyLens", targets: ["CopyLens"])
    ],
    targets: [
        .executableTarget(
            name: "CopyLens",
            path: "Sources/CopyLens"
        ),
        .testTarget(
            name: "CopyLensTests",
            dependencies: ["CopyLens"],
            path: "Tests/CopyLensTests"
        )
    ]
)
