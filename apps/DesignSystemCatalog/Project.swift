import ProjectDescription

let project = Project(
  name: "DesignSystemCatalog",
  organizationName: "dimasike",
  packages: [
    .package(path: "../../")
  ],
  targets: [
    .target(
      name: "DesignSystemCatalog",
      destinations: [.iPhone, .iPad, .mac, .appleTv, .appleVision],
      product: .app,
      bundleId: "com.dimasike.DesignSystemCatalog",
      deploymentTargets: .multiplatform(
        iOS: "26.0",
        macOS: "26.0",
        tvOS: "26.0",
        visionOS: "26.0"
      ),
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": .dictionary([:])
        ]
      ),
      buildableFolders: [
        "AppSources",
        "CatalogSources"
      ],
      dependencies: [
        .package(product: "DesignSystem")
      ]
    ),
    .target(
      name: "DesignSystemCatalogWatch",
      destinations: [.appleWatch],
      product: .app,
      bundleId: "com.dimasike.DesignSystemCatalog.watch",
      deploymentTargets: .watchOS("26.0"),
      infoPlist: .extendingDefault(
        with: [
          "WKApplication": .boolean(true),
          "WKWatchOnly": .boolean(true)
        ]
      ),
      buildableFolders: [
        "WatchSources",
        "CatalogSources"
      ],
      dependencies: [
        .package(product: "DesignSystem")
      ]
    )
  ]
)
