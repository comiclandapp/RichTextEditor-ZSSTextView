// swift-tools-version: 5.10.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RichTextEditor",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RichTextEditor",
            targets: ["RichTextEditor",
                      "ZSSTextView",
                      "InfomaniakRichHTMLEditor"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ZSSTextView",
            path: "Sources/ZSSTextView"
        ),
        .target(
            name: "InfomaniakRichHTMLEditor",
            path: "Sources/InfomaniakRichHTMLEditor",
            resources: [
                .process("Resources/")
            ]
        ),
        .target(
            name: "RichTextEditor",
            dependencies: [
                "ZSSTextView",
                "InfomaniakRichHTMLEditor"
            ],
            path: "Sources/RichTextEditor",
            resources: [
                .process("Resources/")
            ]
        )
    ]
)
