// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AppleSlices",
    platforms: [
        .macOS(.v11)  // Changed from .v11_0 to .v11
    ],
    products: [
        .executable(name: "AppleSlices", targets: ["AppleSlices"]),
    ],
    dependencies: [
        // Add any dependencies here
    ],
    targets: [
        .executableTarget(
            name: "AppleSlices",
            dependencies: [],
            resources: [
                // .process("AppleSlices.entitlements"),
                // .process("Info.plist")
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-enable-bare-slash-regex"])
            ]
        )
    ]
)
