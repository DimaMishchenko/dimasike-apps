import ProjectDescription

let emojiMatchTargetSettings = Settings.settings(
  base: [
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
    "STRING_CATALOG_GENERATE_SYMBOLS": "YES"
  ]
)

let project = Project(
  name: "EmojiMatch",
  organizationName: "dimasike",
  packages: [
    .package(path: "../../")
  ],
  targets: [
    .target(
      name: "AccessibilitySupport",
      destinations: [.mac],
      product: .framework,
      bundleId: "com.dimasike.EmojiMatch.AccessibilitySupport",
      deploymentTargets: .macOS("26.0"),
      buildableFolders: [
        "Feature/AccessibilitySupport/Sources"
      ],
      settings: emojiMatchTargetSettings
    ),
    .target(
      name: "EmojiMatch",
      destinations: [.mac],
      product: .app,
      bundleId: "com.dimasike.EmojiMatch",
      deploymentTargets: .macOS("26.0"),
      infoPlist: .extendingDefault(
        with: [
          "LSUIElement": .boolean(true)
        ]
      ),
      buildableFolders: [
        "AppSources",
        "Resources"
      ],
      dependencies: [
        .package(product: "DesignSystem"),
        .package(product: "Emojis"),
        .target(name: "AccessibilitySupport")
      ],
      settings: emojiMatchTargetSettings
    ),
    .target(
      name: "AccessibilitySupportTests",
      destinations: [.mac],
      product: .unitTests,
      bundleId: "com.dimasike.EmojiMatch.AccessibilitySupportTests",
      deploymentTargets: .macOS("26.0"),
      buildableFolders: [
        "Feature/AccessibilitySupport/Tests"
      ],
      dependencies: [
        .target(name: "AccessibilitySupport")
      ],
      settings: emojiMatchTargetSettings
    )
  ],
  schemes: [
    Scheme.scheme(
      name: "AccessibilitySupport",
      buildAction: .buildAction(
        targets: [
          .target("AccessibilitySupport"),
          .target("AccessibilitySupportTests")
        ]
      ),
      testAction: .targets(
        [
          .testableTarget(target: .target("AccessibilitySupportTests"))
        ]
      )
    )
  ],
  additionalFiles: [
    .glob(pattern: "Feature/**/README.md")
  ]
)
