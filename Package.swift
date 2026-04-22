// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CenterScreen",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "CenterScreen",
            path: "Sources/CenterScreen",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices")
            ]
        )
    ]
)
