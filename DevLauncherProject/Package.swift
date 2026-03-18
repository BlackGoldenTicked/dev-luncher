// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevLauncher",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DevLauncher", targets: ["DevLauncher"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
        .package(url: "https://github.com/krisk/fuse-swift.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DevLauncher",
            dependencies: [
                "HotKey",
                .product(name: "Fuse", package: "fuse-swift")
            ],
            path: "Sources/DevLauncher"
        )
    ]
)
