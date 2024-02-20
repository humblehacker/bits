// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "ContentFeature", targets: ["ContentFeature"]),
        .library(name: "DataStore", targets: ["DataStore"]),
        .library(name: "DataStoreLive", targets: ["DataStoreLive"]),
        .library(name: "ExpressionEvaluator", targets: ["ExpressionEvaluator"]),
        .library(name: "HistoryFeature", targets: ["HistoryFeature"]),
        .library(name: "UI", targets: ["UI"]),
        .library(name: "Utils", targets: ["Utils"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt", from: "5.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.8.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.24.2"),
        .package(url: "https://github.com/tgrapperon/swift-dependencies-additions", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "ContentFeature",
                "DataStoreLive",
            ]
        ),
        .target(
            name: "ContentFeature",
            dependencies: [
                "ExpressionEvaluator",
                "HistoryFeature",
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "HistoryFeature",
            dependencies: [
                "DataStore",
                "UI",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
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
        .target(
            name: "DataStore",
            dependencies: [
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "DataStoreLive",
            dependencies: [
                "DataStore",
                "Utils",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .target(name: "UI"),
        .target(name: "Utils"),
        .testTarget(name: "ContentFeatureTests", dependencies: ["ContentFeature"]),
        .testTarget(name: "ExpressionEvaluatorTests", dependencies: ["ExpressionEvaluator"]),
        .testTarget(name: "HistoryFeatureTests", dependencies: ["HistoryFeature"]),
    ]
)
