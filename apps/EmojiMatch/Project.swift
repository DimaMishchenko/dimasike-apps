import ProjectDescription

let project = Project(
  name: "EmojiMatch",
  organizationName: "dimasike",
  packages: [
    .package(path: "../../")
  ],
  targets: [
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
        "AppSources"
      ]
    )
  ]
)
