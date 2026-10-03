// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "screenshot_detect",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "screenshot-detect", targets: ["screenshot_detect"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "screenshot_detect",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
