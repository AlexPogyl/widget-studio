// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WidgetStudio",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WidgetStudio", targets: ["WidgetStudio"])
    ],
    targets: [
        .executableTarget(
            name: "WidgetStudio",
            path: "Sources/WidgetStudio"
        )
    ]
)
