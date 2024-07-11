// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "monri-ios",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "Monri",
            targets: ["MonriSDK", "AlamofireSDK"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "MonriSDK",
            path: "Monri.xcframework"
        ),
        .binaryTarget(
            name: "AlamofireSDK",
            path: "Alamofire.xcframework"
        )
    ]
)



