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
        .package(url: "https://github.com/LiYanan2004/MarkdownView.git", branch: "main")
    ],
    targets: [
        .target(
            name: "AIChatUI",
            dependencies: ["MarkdownView"],
            path: "Sources/AIChatUI"
        )
    ]
)
