// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PYPlayer",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PYPlayer",
            targets: ["PYPlayer"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", branch: "version6-xcode13"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PYPlayer",
            dependencies: ["IJKMediaFramework",
                          "SwiftUIX",
                          "Kingfisher"]),
        .binaryTarget(name: "IJKMediaFramework", path: "IJKMediaFramework.xcframework"),
        .testTarget(
            name: "PYPlayerTests",
            dependencies: ["PYPlayer"]),
    ]
)
