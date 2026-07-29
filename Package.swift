// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "APIClientKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .macCatalyst(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "APIClientKit",
            targets: ["APIClientKit"]
        ),
        .library(
            name: "APIClientKitURLSession",
            targets: ["APIClientKitURLSession"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "APIClientKit"
        ),
        .target(
            name: "APIClientKitURLSession",
            dependencies: ["APIClientKit"]
        ),
        .testTarget(
            name: "APIClientKitTests",
            dependencies: ["APIClientKit", "APIClientKitURLSession"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
