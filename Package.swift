// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Superscript",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_12),
    .watchOS("6.2")
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "Superscript",
      targets: ["Superscript"]
    )
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "Superscript",
      dependencies: [
        .target(name: "libcel")
      ]
    ),
    .binaryTarget(
      name: "libcel",
      path: "./Frameworks/libcel.xcframework"
    ),
    .testTarget(
      name: "SuperscriptTests",
      dependencies: ["Superscript"]
    )
  ]
)
