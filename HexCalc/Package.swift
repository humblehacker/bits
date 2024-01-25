// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HexCalc",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "ContentFeature", targets: ["ContentFeature"]),
        .library(name: "HistoryFeature", targets: ["HistoryFeature"]),
        .library(name: "ExpressionEvaluator", targets: ["ExpressionEvaluator"]),
        .library(name: "UI", targets: ["UI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "observation-beta"),
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "ContentFeature",
                "HistoryFeature",
            ]
        ),
        .target(
            name: "ContentFeature",
            dependencies: [
                "ExpressionEvaluator",
                "HistoryFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HistoryFeature",
            dependencies: [
                "UI",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "ExpressionEvaluator",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(name: "UI"),
        .testTarget(name: "ContentFeatureTests", dependencies: ["ContentFeature"]),
        .testTarget(name: "ExpressionEvaluatorTests", dependencies: ["ExpressionEvaluator"]),
        .testTarget(name: "HistoryFeatureTests", dependencies: ["HistoryFeature"]),
    ]
)
