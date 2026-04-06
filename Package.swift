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
    ),
    .library(
      name: "Emojis",
      targets: ["Emojis"]
    ),
    .executable(
      name: "emoji",
      targets: ["EmojiKit"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.1"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.3.1")
  ],
  targets: [
    .target(
      name: "DesignSystem",
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .target(
      name: "Emojis",
      resources: [
        .process("Resources")
      ]
    ),
    .executableTarget(
      name: "EmojiKit",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Crypto", package: "swift-crypto")
      ]
    ),
    .testTarget(
      name: "DesignSystemTests",
      dependencies: ["DesignSystem"],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .testTarget(
      name: "EmojisTests",
      dependencies: ["Emojis"]
    ),
    .testTarget(
      name: "EmojiKitTests",
      dependencies: ["EmojiKit"]
    ),
    .testTarget(
      name: "EmojiKitIntegrationTests",
      dependencies: ["EmojiKit"]
    )
  ],
  swiftLanguageModes: [.v6]
)
