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
    targets: [
        .target(
            name: "AIChatUI",
            path: "Sources/AIChatUI"
        )
    ]
)
