// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SuperwallKit",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_12),
    .watchOS("6.2")
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "SuperwallKit",
      targets: ["SuperwallKit"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/superwall/Superscript-iOS", .exact("0.1.17"))
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "SuperwallKit",
      dependencies: [
        .product(name: "Superscript", package: "Superscript-iOS")
      ],
      exclude: ["Resources/BundleHelper.swift"],
      resources: [
        .process("Resources/Certificates"),
        .copy("Resources/PrivacyInfo.xcprivacy")
      ]
    ),
    .testTarget(
      name: "SuperwallKitTests",
      dependencies: ["SuperwallKit"]
    )
  ]
)
