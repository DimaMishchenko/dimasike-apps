## EmojiMatch

App-specific guidance for `apps/EmojiMatch`:

- The `EmojiMatch` app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in
  [Project.swift](/Users/dimamishchenko/Documents/engineering/ios/My/dimasike-apps/dimasike-apps/apps/EmojiMatch/Project.swift:3).
- The `EmojiMatch` app target also enables `SWIFT_APPROACHABLE_CONCURRENCY = YES` in
  [Project.swift](/Users/dimamishchenko/Documents/engineering/ios/My/dimasike-apps/dimasike-apps/apps/EmojiMatch/Project.swift:3).
- Within this app target, prefer relying on main-actor-by-default instead of repeating explicit
  `@MainActor` annotations unless they improve clarity at an API boundary.
