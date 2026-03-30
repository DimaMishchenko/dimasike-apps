// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "dimasike-platform",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
    .tvOS(.v26),
    .watchOS(.v26),
    .visionOS(.v26)
  ],
  products: [
    .library(
      name: "DesignSystem",
      targets: ["DesignSystem"]
    )
  ],
  targets: [
    .target(
      name: "DesignSystem",
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .testTarget(
      name: "DesignSystemTests",
      dependencies: ["DesignSystem"],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
