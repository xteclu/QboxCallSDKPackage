// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QboxCallSDKPackage",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "QboxCallSDK",
            targets: ["QboxCallSDK"]
        ),
    ],
    dependencies: [
      .package(url: "https://github.com/stasel/WebRTC.git", from: "126.0.0"),
      .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
          name: "QboxCallSDK",
          dependencies: [
            .product(name: "WebRTC", package: "WebRTC"),
            .product(name: "Starscream", package: "Starscream"),
          ]
        )
    ]
)
