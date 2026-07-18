// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AIChatUI",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "AIChatUI",
            targets: ["AIChatUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/guoPhineas/MarkdownView", branch: "phg/features/260716")
    ],
    targets: [
        .target(
            name: "AIChatUI",
            dependencies: ["MarkdownView"],
            path: "Sources/AIChatUI"
        )
    ]
)
